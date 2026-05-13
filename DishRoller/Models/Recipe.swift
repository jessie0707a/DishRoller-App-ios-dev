//
//  Recipe.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var estimatedTime: String
    var flavourTags: [String]
    var ingredients: [RecipeIngredient]
    var procedure: [RecipeProcedureStep]
    var isSaved: Bool

    init(
        id: UUID = UUID(),
        title: String,
        estimatedTime: String,
        flavourTags: [String],
        ingredients: [RecipeIngredient],
        procedure: [String],
        isSaved: Bool = false
    ) {
        self.init(
            id: id,
            title: title,
            estimatedTime: estimatedTime,
            flavourTags: flavourTags,
            ingredients: ingredients,
            procedure: procedure.map { RecipeProcedureStep(instruction: $0) },
            isSaved: isSaved
        )
    }

    init(
        id: UUID = UUID(),
        title: String,
        estimatedTime: String,
        flavourTags: [String],
        ingredients: [RecipeIngredient],
        procedure: [RecipeProcedureStep],
        isSaved: Bool = false
    ) {
        self.id = id
        self.title = title
        self.estimatedTime = estimatedTime
        self.flavourTags = flavourTags
        self.ingredients = ingredients
        self.procedure = procedure
        self.isSaved = isSaved
    }
}

struct RecipeIngredient: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var amount: String
    var form: String?

    init(id: UUID = UUID(), name: String, amount: String, form: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.form = form
    }
}

struct RecipeProcedureStep: Codable, Equatable {
    var emoji: String
    var instruction: String

    init(emoji: String = "🍳", instruction: String) {
        self.emoji = emoji
        self.instruction = instruction
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let instruction = try? container.decode(String.self) {
            self.emoji = "🍳"
            self.instruction = instruction
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "🍳"
        self.instruction = try container.decode(String.self, forKey: .instruction)
    }
}
