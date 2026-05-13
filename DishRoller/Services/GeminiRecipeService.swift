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

    init() {
        let config = GeminiConfig.load()
        self.session = .shared
        self.apiKey = config.resolvedAPIKey()
        self.model = config.model
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

            return Recipe(
                title: recipeDTO.title,
                estimatedTime: recipeDTO.estimatedTime,
                flavourTags: recipeDTO.flavourTags.map(Self.normalizedFlavourTag),
                ingredients: recipeDTO.ingredients.map {
                    RecipeIngredient(name: $0.name, amount: $0.amount, form: $0.form)
                },
                procedure: recipeDTO.procedure.map {
                    RecipeProcedureStep(emoji: $0.emoji, instruction: $0.instruction)
                }
            )
        } catch {
            throw error
        }
    }

    private static func normalizedFlavourTag(_ tag: String) -> String {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        let inspiredSuffix = " Inspired"

        if trimmedTag.lowercased().hasSuffix(inspiredSuffix.lowercased()) {
            return String(trimmedTag.dropLast(inspiredSuffix.count))
        }

        return trimmedTag
    }
}

private struct GeminiConfig {
    let apiKey: String
    let model: String

    static func load(bundle: Bundle = .main) -> GeminiConfig {
        guard
            let url = bundle.url(forResource: "Config", withExtension: "plist"),
            let values = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            return GeminiConfig(apiKey: "", model: "gemini-2.5-flash-lite")
        }

        let apiKey = values["GEMINI_API_KEY"] as? String ?? ""
        let model = values["GEMINI_MODEL"] as? String ?? "gemini-2.5-flash-lite"
        return GeminiConfig(apiKey: apiKey, model: model)
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
