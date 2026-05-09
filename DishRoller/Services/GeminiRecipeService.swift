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
        style: FlavourStyle
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
        let prompt = """
        You are a cooking assistant.

        Generate one practical recipe based on:
        Ingredients: \(ingredientNames)
        Time: \(time.rawValue)
        Type: \(type.rawValue)
        Style: \(style.rawValue)

        Keep the ingredient list realistic, the steps concise, and the result easy to cook at home.
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
                flavourTags: recipeDTO.flavourTags,
                ingredients: recipeDTO.ingredients.map {
                    RecipeIngredient(name: $0.name, amount: $0.amount)
                },
                procedure: recipeDTO.procedure
            )
        } catch {
            return DemoRecipeFactory.makeRecipe(
                ingredients: ingredients,
                time: time,
                type: type,
                style: style
            )
        }
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
            "amount": ["type": "string"]
        ],
        "required": ["name", "amount"],
        "propertyOrdering": ["name", "amount"]
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
                "items": ["type": "string"]
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
    let procedure: [String]
}

private struct RecipeIngredientDTO: Codable {
    let name: String
    let amount: String
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
                amount: demoAmount(for: $0)
            )
        }

        let fallbackIngredients = recipeIngredients.isEmpty
            ? [RecipeIngredient(name: "Salt", amount: "to taste")]
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
    ) -> [String] {
        let names = ingredients.map(\.name).joined(separator: ", ")
        let styleText = style == .any ? "your preferred seasonings" : "\(style.rawValue.lowercased()) seasonings"

        return [
            "Prepare \(names) and portion everything so the recipe can be finished in about \(time.rawValue.lowercased()).",
            "Cook the main ingredients in a pan or pot, then season with \(styleText) and adjust the taste as needed.",
            "Finish when the ingredients are cooked through, then plate and serve warm as a demo-mode recipe."
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
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
