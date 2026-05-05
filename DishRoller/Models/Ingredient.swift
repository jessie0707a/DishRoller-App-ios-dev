//
//  Ingredient.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation

struct Ingredient: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: IngredientCategory
    var amount: Double
    var unit: UnitType

    init(
        id: UUID = UUID(),
        name: String,
        category: IngredientCategory,
        amount: Double,
        unit: UnitType
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.unit = unit
    }
}
