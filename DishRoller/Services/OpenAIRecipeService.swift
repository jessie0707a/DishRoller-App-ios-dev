//
//  OpenAIRecipeService.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation

final class OpenAIRecipeService {

    // TODO: 請把你的 API Key 放在這裡
    private let apiKey = "YOUR_OPENAI_API_KEY_HERE"

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func generateRecipe(
        ingredients: [Ingredient],
        time: CookingTime,
        type: DishType,
        style: FlavourStyle
    ) async throws -> Recipe {

        let ingredientNames = ingredients.map { $0.name }.joined(separator: ", ")

        let prompt = """
        You are a cooking assistant.

        Generate one recipe based on:
        Ingredients: \(ingredientNames)
        Time: \(time.rawValue)
        Type: \(type.rawValue)
        Style: \(style.rawValue)

        Return ONLY valid JSON in this format:
        {
          "title": "...",
          "estimatedTime": "...",
          "flavourTags": ["..."],
          "ingredients": [
            { "name": "...", "amount": "..." }
          ],
          "procedure": ["...", "..."]
        }
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.8
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = decoded.choices.first?.message.content,
              let jsonData = content.data(using: .utf8)
        else {
            throw URLError(.badServerResponse)
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
    }
}

private struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
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
