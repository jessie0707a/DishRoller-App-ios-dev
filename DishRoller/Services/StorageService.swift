//
//  StorageService.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation

final class StorageService {
    static let shared = StorageService()

    private let ingredientsKey = "dishroller.ingredients"
    private let savedRecipesKey = "dishroller.savedRecipes"
    private let avoidanceProfilesKey = "dishroller.avoidanceProfiles"

    private init() {}

    func saveIngredients(_ ingredients: [Ingredient]) {
        if let data = try? JSONEncoder().encode(ingredients) {
            UserDefaults.standard.set(data, forKey: ingredientsKey)
        }
    }

    func loadIngredients() -> [Ingredient] {
        guard let data = UserDefaults.standard.data(forKey: ingredientsKey),
              let ingredients = try? JSONDecoder().decode([Ingredient].self, from: data)
        else {
            return []
        }
        return ingredients
    }

    func saveRecipes(_ recipes: [Recipe]) {
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: savedRecipesKey)
        }
    }

    func loadRecipes() -> [Recipe] {
        guard let data = UserDefaults.standard.data(forKey: savedRecipesKey),
              let recipes = try? JSONDecoder().decode([Recipe].self, from: data)
        else {
            return []
        }
        return recipes
    }

    func saveAvoidanceProfiles(_ profiles: [AvoidanceProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: avoidanceProfilesKey)
        }
    }

    func loadAvoidanceProfiles() -> [AvoidanceProfile] {
        guard let data = UserDefaults.standard.data(forKey: avoidanceProfilesKey),
              let profiles = try? JSONDecoder().decode([AvoidanceProfile].self, from: data)
        else {
            return []
        }
        return profiles
    }
}
