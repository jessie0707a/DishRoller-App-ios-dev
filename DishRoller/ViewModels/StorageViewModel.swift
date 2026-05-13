//
//  StorageViewModel.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation
import Combine

final class StorageViewModel: ObservableObject {
    @Published var ingredients: [Ingredient] = []
    @Published var selectedFilter: IngredientCategory? = nil
    @Published var searchText: String = ""

    let commonIngredients: [String: [String]] = [
        "MEAT": ["Chicken", "Beef", "Pork", "Lamb", "Bacon"],
        "VEG": ["Potato", "Carrot", "Onion", "Tomato", "Broccoli", "Capsicum"],
        "SEAFOOD": ["Salmon", "Tuna", "Shrimp"],
        "DRINK": ["Milk", "Juice"],
        "CONDIMENT": ["Soy Sauce", "Salt", "Pepper", "Olive Oil"]
    ]

    init() {
        ingredients = StorageService.shared.loadIngredients()

        if ingredients.isEmpty {
            loadSampleData()
        }
    }

    var filteredIngredients: [Ingredient] {
        ingredients.filter { ingredient in
            let matchesCategory = selectedFilter == nil || ingredient.category == selectedFilter
            let matchesSearch = searchText.isEmpty || ingredient.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    func addIngredient(name: String, category: IngredientCategory, amount: Double, unit: UnitType) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, amount > 0 else { return }

        if let index = ingredients.firstIndex(where: {
            $0.name.lowercased() == cleanName.lowercased() && $0.unit == unit
        }) {
            ingredients[index].amount += amount
        } else {
            let newIngredient = Ingredient(
                name: cleanName,
                category: category,
                amount: amount,
                unit: unit
            )
            ingredients.append(newIngredient)
        }

        save()
    }

    func increase(_ ingredient: Ingredient) {
        guard let index = ingredients.firstIndex(of: ingredient) else { return }
        ingredients[index].amount += step(for: ingredients[index].unit)
        save()
    }

    func decrease(_ ingredient: Ingredient) {
        guard let index = ingredients.firstIndex(of: ingredient) else { return }
        ingredients[index].amount -= step(for: ingredients[index].unit)

        if ingredients[index].amount <= 0 {
            ingredients.remove(at: index)
        }

        save()
    }

    func delete(_ ingredient: Ingredient) {
        ingredients.removeAll { $0.id == ingredient.id }
        save()
    }

    private func step(for unit: UnitType) -> Double {
        switch unit {
        case .kg: return 0.1
        case .g: return 50
        case .liter: return 0.1
        case .ml: return 50
        case .pcs: return 1
        }
    }

    private func save() {
        StorageService.shared.saveIngredients(ingredients)
    }

    private func loadSampleData() {
        ingredients = [
            Ingredient(name: "Lamb", category: .meat, amount: 1.6, unit: .kg),
            Ingredient(name: "Pork", category: .meat, amount: 1.6, unit: .kg),
            Ingredient(name: "Chicken", category: .meat, amount: 1.6, unit: .kg),
            Ingredient(name: "Beef", category: .meat, amount: 1.6, unit: .kg),
            Ingredient(name: "Pepper", category: .condiment, amount: 150, unit: .g),
            Ingredient(name: "Soy Sauce", category: .condiment, amount: 1.5, unit: .liter),
            Ingredient(name: "Coriander", category: .veg, amount: 500, unit: .g),
            Ingredient(name: "Shrimp", category: .seafood, amount: 500, unit: .g),
            Ingredient(name: "Milk", category: .drink, amount: 2, unit: .liter)
        ]
        save()
    }
}
