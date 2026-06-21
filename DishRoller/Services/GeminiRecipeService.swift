//
//  GeminiRecipeService.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation

final class GeminiRecipeService {
    private let session: URLSession
    private let apiKey: String
    private let model: String
    private let imageModel: String

    init() {
        let config = GeminiConfig.load()
        self.session = .shared
        self.apiKey = config.resolvedAPIKey()
        self.model = config.model
        self.imageModel = config.imageModel
    }

    func generateRecipe(
        ingredients: [Ingredient],
        time: CookingTime,
        type: DishType,
        style: FlavourStyle,
        customPreferences: String,
        avoidancePrompt: String
    ) async throws -> Recipe {
        guard !apiKey.isEmpty else {
            return DemoRecipeFactory.makeRecipe(
                ingredients: ingredients,
                time: time,
                type: type,
                style: style
            )
        }

        let ingredientNames = ingredients.map { $0.name }.joined(separator: ", ")
        let trimmedPreferences = customPreferences.trimmingCharacters(in: .whitespacesAndNewlines)
        let preferenceInstruction = trimmedPreferences.isEmpty
            ? "No extra user preferences provided."
            : trimmedPreferences
        let trimmedAvoidancePrompt = avoidancePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let avoidanceInstruction = trimmedAvoidancePrompt.isEmpty
            ? "No avoid-food preferences selected."
            : "Strictly avoid these foods for the selected people: \(trimmedAvoidancePrompt). Do not include them, obvious variants, or close substitutes anywhere in the recipe."
        let prompt = """
        You are DishRoller's recipe generator. Create one practical home-cooking recipe that fits the user's selected ingredients and preferences.

        User selections:
        - Selected ingredients: \(ingredientNames)
        - Target cooking time: \(time.rawValue)
        - Dish type: \(type.rawValue)
        - Flavour style: \(style.rawValue)
        - Extra preferences: \(preferenceInstruction)
        - Avoid-food rules: \(avoidanceInstruction)

        Recipe rules:
        - Use the selected ingredients as the main direction of the dish. You may add common pantry staples only when needed, such as oil, salt, pepper, water, sugar, soy sauce, vinegar, flour, or stock.
        - Keep the recipe realistic for a normal home kitchen and achievable within the target cooking time.
        - Respect the dish type, flavour style, and extra preferences unless they conflict with avoid-food rules.
        - Treat extra preferences as guidance for dietary needs, texture, cooking method, spice level, serving style, or cuisine details.
        - Avoid all avoid-food items completely in the title, flavour tags, ingredient list, and procedure.
        - If a selected ingredient conflicts with avoid-food rules, omit it and build the recipe around the remaining safe ingredients.

        Output quality rules:
        - title: concise, appetizing, and specific.
        - estimatedTime: use a short value like "15 min", "30 min", or "1 hr".
        - flavourTags: return 2 to 4 short tags. Use direct cuisine names like "Japanese", not "Japanese Inspired".
        - ingredients: return practical cooking amounts. Keep name as the base ingredient only, such as "Garlic" instead of "Minced garlic".
        - ingredient amount: use compact cooking units such as "1 tsp", "1 cup", "2 pcs", "200 g", or "to taste".
        - ingredient form: put preparation or ingredient form here, such as "minced", "sliced", "diced", "whole", "fillet", "paste", "ground", or "fresh". Use "prepared" if no clearer form applies.
        - procedure: return 3 to 6 concise steps in cooking order. Each step must include one matching cooking emoji and one clear instruction.
        """

        guard let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent") else {
            throw GeminiRecipeServiceError.invalidConfiguration("Invalid Gemini model configuration.")
        }

        let requestBody = RecipeSchema.requestBody(for: prompt)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiRecipeServiceError.invalidResponse
            }

            if !(200...299).contains(httpResponse.statusCode) {
                let apiError = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data)
                let message = apiError?.error.message ?? "Gemini API returned status code \(httpResponse.statusCode)."
                throw GeminiRecipeServiceError.apiError(message)
            }

            let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
            guard
                let text = decoded.candidates.first?.content.parts
                    .compactMap(\.text)
                    .joined()
                    .nonEmpty,
                let jsonData = text.data(using: .utf8)
            else {
                throw GeminiRecipeServiceError.invalidResponse
            }

            let recipeDTO = try JSONDecoder().decode(RecipeDTO.self, from: jsonData)
            let recipeID = UUID()
            let imageFileName = await generateAndSaveDishImage(
                recipeID: recipeID,
                title: recipeDTO.title,
                ingredients: recipeDTO.ingredients.map(\.name),
                flavourTags: recipeDTO.flavourTags
            )

            return Recipe(
                id: recipeID,
                title: recipeDTO.title,
                estimatedTime: recipeDTO.estimatedTime,
                flavourTags: recipeDTO.flavourTags.map(Self.normalizedFlavourTag),
                ingredients: recipeDTO.ingredients.map {
                    RecipeIngredient(name: $0.name, amount: $0.amount, form: $0.form)
                },
                procedure: recipeDTO.procedure.map {
                    RecipeProcedureStep(emoji: $0.emoji, instruction: $0.instruction)
                },
                imageFileName: imageFileName
            )
        } catch {
            throw error
        }
    }

    func estimateExpiryDate(itemName: String, purchaseDate: Date) async throws -> Date {
        let cleanName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            throw GeminiRecipeServiceError.invalidConfiguration("Enter the food name before estimating.")
        }

        guard !apiKey.isEmpty else {
            return Calendar.current.date(byAdding: .day, value: 5, to: purchaseDate) ?? purchaseDate
        }

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let purchaseDateText = dateFormatter.string(from: purchaseDate)

        let prompt = """
        Estimate a conservative home-storage expiry date for this food item.

        Food item: \(cleanName)
        Purchase date: \(purchaseDateText)

        Use reputable food-safety and storage references found through Google Search. Assume the item is unopened or freshly purchased, stored correctly in a normal household refrigerator when refrigeration is normally required, and otherwise stored according to standard guidance. Choose a cautious practical date rather than the longest possible shelf life.

        Return only the estimated expiry date and a short reason. The expiry date must be on or after the purchase date.
        """

        guard let endpoint = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        ) else {
            throw GeminiRecipeServiceError.invalidConfiguration("Invalid Gemini model configuration.")
        }

        let groundedPrompt = prompt + """

        Respond with only one JSON object in exactly this format:
        {"expiryDate":"YYYY-MM-DD","reason":"short reason"}
        Do not use Markdown or code fences.
        """

        let estimate: ExpiryEstimateDTO
        do {
            let responseText = try await requestExpiryEstimate(
                endpoint: endpoint,
                prompt: groundedPrompt,
                usesGoogleSearch: true,
                usesStructuredOutput: false
            )
            estimate = try Self.decodeExpiryEstimate(from: responseText)
        } catch {
            let responseText = try await requestExpiryEstimate(
                endpoint: endpoint,
                prompt: prompt,
                usesGoogleSearch: false,
                usesStructuredOutput: true
            )
            estimate = try Self.decodeExpiryEstimate(from: responseText)
        }

        guard let estimatedDate = dateFormatter.date(from: estimate.expiryDate) else {
            throw GeminiRecipeServiceError.invalidResponse
        }

        return max(
            Calendar.current.startOfDay(for: purchaseDate),
            Calendar.current.startOfDay(for: estimatedDate)
        )
    }

    private func requestExpiryEstimate(
        endpoint: URL,
        prompt: String,
        usesGoogleSearch: Bool,
        usesStructuredOutput: Bool
    ) async throws -> String {
        var generationConfig: [String: Any] = [
            "temperature": 0.2
        ]

        if usesStructuredOutput {
            generationConfig["responseMimeType"] = "application/json"
            generationConfig["responseSchema"] = [
                "type": "object",
                "properties": [
                    "expiryDate": [
                        "type": "string",
                        "description": "Estimated expiry date in YYYY-MM-DD format"
                    ],
                    "reason": ["type": "string"]
                ],
                "required": ["expiryDate", "reason"],
                "propertyOrdering": ["expiryDate", "reason"]
            ]
        }

        var requestBody: [String: Any] = [
            "contents": [[
                "parts": [["text": prompt]]
            ]],
            "generationConfig": generationConfig
        ]

        if usesGoogleSearch {
            requestBody["tools"] = [["google_search": [:]]]
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiRecipeServiceError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let apiError = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data)
            throw GeminiRecipeServiceError.apiError(
                apiError?.error.message ?? "Gemini API returned status code \(httpResponse.statusCode)."
            )
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        guard let text = decoded.candidates.first?.content.parts
            .compactMap(\.text)
            .joined()
            .nonEmpty else {
            throw GeminiRecipeServiceError.invalidResponse
        }
        return text
    }

    private static func decodeExpiryEstimate(from text: String) throws -> ExpiryEstimateDTO {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           let estimate = try? JSONDecoder().decode(ExpiryEstimateDTO.self, from: data) {
            return estimate
        }

        guard let openingBrace = trimmed.firstIndex(of: "{"),
              let closingBrace = trimmed.lastIndex(of: "}"),
              openingBrace <= closingBrace,
              let data = String(trimmed[openingBrace...closingBrace]).data(using: .utf8) else {
            throw GeminiRecipeServiceError.invalidResponse
        }

        return try JSONDecoder().decode(ExpiryEstimateDTO.self, from: data)
    }

    private static func normalizedFlavourTag(_ tag: String) -> String {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        let inspiredSuffix = " Inspired"

        if trimmedTag.lowercased().hasSuffix(inspiredSuffix.lowercased()) {
            return String(trimmedTag.dropLast(inspiredSuffix.count))
        }

        return trimmedTag
    }

    private func generateAndSaveDishImage(
        recipeID: UUID,
        title: String,
        ingredients: [String],
        flavourTags: [String]
    ) async -> String? {
        let prompt = """
        Use Google Image Search grounding to understand how this dish and cuisine should look, then create one realistic editorial food photograph for the recipe "\(title)".

        Main ingredients: \(ingredients.joined(separator: ", "))
        Style tags: \(flavourTags.joined(separator: ", "))

        Show the completed dish clearly as the main subject. Use natural restaurant-quality lighting, a clean plate, realistic portions, accurate ingredients, and a slightly elevated camera angle. Landscape 4:3 composition. No people, hands, packaging, logos, watermarks, labels, borders, or text.
        """

        if let image = try? await requestDishImage(
            prompt: prompt,
            model: imageModel,
            usesGoogleSearch: true
        ) {
            return RecipeImageStore.shared.save(
                image.data,
                recipeID: recipeID,
                mimeType: image.mimeType
            )
        }

        guard imageModel != "gemini-2.5-flash-image",
              let image = try? await requestDishImage(
                prompt: prompt,
                model: "gemini-2.5-flash-image",
                usesGoogleSearch: false
              )
        else {
            return nil
        }

        return RecipeImageStore.shared.save(
            image.data,
            recipeID: recipeID,
            mimeType: image.mimeType
        )
    }

    private func requestDishImage(
        prompt: String,
        model: String,
        usesGoogleSearch: Bool
    ) async throws -> GeneratedDishImage {
        guard let endpoint = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        ) else {
            throw GeminiRecipeServiceError.invalidConfiguration("Invalid Gemini image model configuration.")
        }

        var requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["TEXT", "IMAGE"]
            ]
        ]

        if usesGoogleSearch {
            requestBody["tools"] = [["google_search": [:]]]
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiRecipeServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiError = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data)
            throw GeminiRecipeServiceError.apiError(
                apiError?.error.message ?? "Gemini image API returned status code \(httpResponse.statusCode)."
            )
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        guard let inlineData = decoded.candidates
            .flatMap(\.content.parts)
            .compactMap(\.inlineData)
            .first,
              let imageData = Data(base64Encoded: inlineData.data)
        else {
            throw GeminiRecipeServiceError.invalidResponse
        }

        return GeneratedDishImage(data: imageData, mimeType: inlineData.mimeType)
    }
}

private struct GeminiConfig {
    let apiKey: String
    let model: String
    let imageModel: String

    static func load(bundle: Bundle = .main) -> GeminiConfig {
        guard
            let url = bundle.url(forResource: "Config", withExtension: "plist"),
            let values = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            return GeminiConfig(
                apiKey: "",
                model: "gemini-2.5-flash-lite",
                imageModel: "gemini-3.1-flash-image"
            )
        }

        let apiKey = values["GEMINI_API_KEY"] as? String ?? ""
        let model = values["GEMINI_MODEL"] as? String ?? "gemini-2.5-flash-lite"
        let imageModel = values["GEMINI_IMAGE_MODEL"] as? String ?? "gemini-3.1-flash-image"
        return GeminiConfig(apiKey: apiKey, model: model, imageModel: imageModel)
    }

    func resolvedAPIKey() -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, trimmedKey != "YOUR_GEMINI_API_KEY" else { return "" }
        return trimmedKey
    }
}

private enum GeminiRecipeServiceError: LocalizedError {
    case invalidConfiguration(String)
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return message
        case .apiError(let message):
            return message
        case .invalidResponse:
            return "Gemini returned an invalid recipe response."
        }
    }
}

private struct GeminiPart: Codable {
    let text: String?
    let inlineData: GeminiInlineData?
}

private struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String
}

private struct GeneratedDishImage {
    let data: Data
    let mimeType: String
}

private enum RecipeSchema {
    static func requestBody(for prompt: String) -> [String: Any] {
        [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "responseMimeType": "application/json",
                "responseSchema": recipeSchema
            ]
        ]
    }

    private static let recipeIngredientSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "name": ["type": "string"],
            "amount": ["type": "string"],
            "form": ["type": "string"]
        ],
        "required": ["name", "amount", "form"],
        "propertyOrdering": ["name", "amount", "form"]
    ]

    private static let procedureStepSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "emoji": ["type": "string"],
            "instruction": ["type": "string"]
        ],
        "required": ["emoji", "instruction"],
        "propertyOrdering": ["emoji", "instruction"]
    ]

    private static let recipeSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "title": ["type": "string"],
            "estimatedTime": ["type": "string"],
            "flavourTags": [
                "type": "array",
                "items": ["type": "string"]
            ],
            "ingredients": [
                "type": "array",
                "items": recipeIngredientSchema
            ],
            "procedure": [
                "type": "array",
                "items": procedureStepSchema
            ]
        ],
        "required": ["title", "estimatedTime", "flavourTags", "ingredients", "procedure"],
        "propertyOrdering": ["title", "estimatedTime", "flavourTags", "ingredients", "procedure"]
    ]
}

private struct GeminiGenerateContentResponse: Codable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Codable {
    let content: GeminiCandidateContent
}

private struct GeminiCandidateContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiErrorResponse: Codable {
    let error: GeminiErrorPayload
}

private struct GeminiErrorPayload: Codable {
    let message: String
}

private struct RecipeDTO: Codable {
    let title: String
    let estimatedTime: String
    let flavourTags: [String]
    let ingredients: [RecipeIngredientDTO]
    let procedure: [RecipeProcedureStepDTO]
}

private struct RecipeIngredientDTO: Codable {
    let name: String
    let amount: String
    let form: String
}

private struct RecipeProcedureStepDTO: Codable {
    let emoji: String
    let instruction: String
}

private struct ExpiryEstimateDTO: Codable {
    let expiryDate: String
    let reason: String
}

private enum DemoRecipeFactory {
    static func makeRecipe(
        ingredients: [Ingredient],
        time: CookingTime,
        type: DishType,
        style: FlavourStyle
    ) -> Recipe {
        let leadIngredient = ingredients.first?.name ?? "Chef's Choice"
        let recipeTitle = demoTitle(
            leadIngredient: leadIngredient,
            type: type,
            style: style
        )

        let recipeIngredients = ingredients.map {
            RecipeIngredient(
                name: $0.name,
                amount: demoAmount(for: $0),
                form: demoForm(for: $0)
            )
        }

        let fallbackIngredients = recipeIngredients.isEmpty
            ? [RecipeIngredient(name: "Salt", amount: "to taste", form: "fine")]
            : recipeIngredients

        return Recipe(
            title: recipeTitle,
            estimatedTime: time.rawValue,
            flavourTags: demoTags(style: style, type: type),
            ingredients: fallbackIngredients,
            procedure: demoProcedure(
                ingredients: fallbackIngredients,
                time: time,
                style: style
            )
        )
    }

    private static func demoTitle(
        leadIngredient: String,
        type: DishType,
        style: FlavourStyle
    ) -> String {
        let stylePrefix = style == .any ? "Demo" : style.rawValue
        let typeSuffix = type == .any ? "Special" : type.rawValue
        return "\(stylePrefix) \(leadIngredient) \(typeSuffix)"
    }

    private static func demoTags(style: FlavourStyle, type: DishType) -> [String] {
        let styleTag = style == .any ? "Demo Mode" : style.rawValue
        let typeTag = type == .any ? "Home Cooking" : type.rawValue
        return [styleTag, typeTag, "Fallback Recipe"]
    }

    private static func demoProcedure(
        ingredients: [RecipeIngredient],
        time: CookingTime,
        style: FlavourStyle
    ) -> [RecipeProcedureStep] {
        let names = ingredients.map(\.name).joined(separator: ", ")
        let styleText = style == .any ? "your preferred seasonings" : "\(style.rawValue.lowercased()) seasonings"

        return [
            RecipeProcedureStep(
                emoji: "🔪",
                instruction: "Prepare \(names) and portion everything so the recipe can be finished in about \(time.rawValue.lowercased())."
            ),
            RecipeProcedureStep(
                emoji: "🔥",
                instruction: "Cook the main ingredients in a pan or pot, then season with \(styleText) and adjust the taste as needed."
            ),
            RecipeProcedureStep(
                emoji: "🍽️",
                instruction: "Finish when the ingredients are cooked through, then plate and serve warm as a demo-mode recipe."
            )
        ]
    }

    private static func demoAmount(for ingredient: Ingredient) -> String {
        let formattedAmount: String
        if ingredient.amount == floor(ingredient.amount) {
            formattedAmount = String(Int(ingredient.amount))
        } else {
            formattedAmount = String(format: "%.1f", ingredient.amount)
        }

        return "\(formattedAmount) \(ingredient.unit.rawValue)"
    }

    private static func demoForm(for ingredient: Ingredient) -> String {
        switch ingredient.category {
        case .meat:
            return "sliced"
        case .seafood:
            return "fillet"
        case .veg:
            return "chopped"
        case .drink:
            return "liquid"
        case .condiment:
            return "paste"
        }
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
