//
//  SwiftDataRecords.swift
//  DishRoller
//

import Foundation
import SwiftData

@Model
final class StoredIngredientRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRawValue: String
    var amount: Double
    var unitRawValue: String
    var iconName: String?
    var imageData: Data?
    var orderIndex: Int

    init(ingredient: Ingredient, orderIndex: Int) {
        self.id = ingredient.id
        self.name = ingredient.name
        self.categoryRawValue = ingredient.category.rawValue
        self.amount = ingredient.amount
        self.unitRawValue = ingredient.unit.rawValue
        self.iconName = ingredient.iconName
        self.imageData = ingredient.imageData
        self.orderIndex = orderIndex
    }

    func update(from ingredient: Ingredient, orderIndex: Int) {
        name = ingredient.name
        categoryRawValue = ingredient.category.rawValue
        amount = ingredient.amount
        unitRawValue = ingredient.unit.rawValue
        iconName = ingredient.iconName
        imageData = ingredient.imageData
        self.orderIndex = orderIndex
    }

    func toIngredient() -> Ingredient {
        Ingredient(
            id: id,
            name: name,
            category: IngredientCategory(rawValue: categoryRawValue) ?? .veg,
            amount: amount,
            unit: UnitType(rawValue: unitRawValue) ?? .pcs,
            iconName: iconName,
            imageData: imageData
        )
    }
}

@Model
final class StoredRecipeRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var estimatedTime: String
    var flavourTagsData: Data
    var ingredientsData: Data
    var procedureData: Data
    var isSaved: Bool
    var orderIndex: Int

    init(recipe: Recipe, orderIndex: Int) {
        self.id = recipe.id
        self.title = recipe.title
        self.estimatedTime = recipe.estimatedTime
        self.flavourTagsData = Self.encode(recipe.flavourTags)
        self.ingredientsData = Self.encode(recipe.ingredients)
        self.procedureData = Self.encode(recipe.procedure)
        self.isSaved = recipe.isSaved
        self.orderIndex = orderIndex
    }

    func update(from recipe: Recipe, orderIndex: Int) {
        title = recipe.title
        estimatedTime = recipe.estimatedTime
        flavourTagsData = Self.encode(recipe.flavourTags)
        ingredientsData = Self.encode(recipe.ingredients)
        procedureData = Self.encode(recipe.procedure)
        isSaved = recipe.isSaved
        self.orderIndex = orderIndex
    }

    func toRecipe() -> Recipe {
        Recipe(
            id: id,
            title: title,
            estimatedTime: estimatedTime,
            flavourTags: Self.decode([String].self, from: flavourTagsData, fallback: []),
            ingredients: Self.decode([RecipeIngredient].self, from: ingredientsData, fallback: []),
            procedure: Self.decode([RecipeProcedureStep].self, from: procedureData, fallback: []),
            isSaved: isSaved
        )
    }

    private static func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data, fallback: T) -> T {
        guard !data.isEmpty else { return fallback }
        return (try? JSONDecoder().decode(type, from: data)) ?? fallback
    }
}

@Model
final class StoredAvoidanceProfileRecord {
    @Attribute(.unique) var id: UUID
    var personName: String
    var avoidFoods: String
    var isSelected: Bool
    var orderIndex: Int

    init(profile: AvoidanceProfile, orderIndex: Int) {
        self.id = profile.id
        self.personName = profile.personName
        self.avoidFoods = profile.avoidFoods
        self.isSelected = profile.isSelected
        self.orderIndex = orderIndex
    }

    func update(from profile: AvoidanceProfile, orderIndex: Int) {
        personName = profile.personName
        avoidFoods = profile.avoidFoods
        isSelected = profile.isSelected
        self.orderIndex = orderIndex
    }

    func toProfile() -> AvoidanceProfile {
        AvoidanceProfile(
            id: id,
            personName: personName,
            avoidFoods: avoidFoods,
            isSelected: isSelected
        )
    }
}
