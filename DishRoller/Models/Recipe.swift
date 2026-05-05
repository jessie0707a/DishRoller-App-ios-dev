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
    var procedure: [String]
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

    init(id: UUID = UUID(), name: String, amount: String) {
        self.id = id
        self.name = name
        self.amount = amount
    }
}
