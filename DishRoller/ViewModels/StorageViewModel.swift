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
    @Published var shoppingListItems: [ShoppingListItem] = []
    @Published var selectedFilter: IngredientCategory? = nil
    @Published var searchText: String = ""

    private let shoppingListKey = "dishroller.shoppingListItems"

    let commonIngredients: [String: [String]] = [
        "MEAT": ["Chicken", "Beef", "Pork", "Lamb", "Bacon"],
        "VEG": ["Potato", "Carrot", "Onion", "Tomato", "Broccoli", "Capsicum"],
        "SEAFOOD": ["Salmon", "Tuna", "Shrimp"],
        "DRINK": ["Milk", "Juice"],
        "CONDIMENT": ["Soy Sauce", "Salt", "Pepper", "Olive Oil"]
    ]

    init() {
        ingredients = StorageService.shared.loadIngredients()
        shoppingListItems = loadShoppingListItems()

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

    func addIngredient(
        name: String,
        category: IngredientCategory,
        amount: Double,
        unit: UnitType,
        iconName: String? = nil,
        imageData: Data? = nil
    ) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, amount > 0 else { return }

        if let index = ingredients.firstIndex(where: {
            $0.name.lowercased() == cleanName.lowercased() && $0.unit == unit
        }) {
            ingredients[index].amount += amount
            ingredients[index].category = category
            if let iconName {
                ingredients[index].iconName = iconName
            }
            if let imageData {
                ingredients[index].imageData = imageData
            }
        } else {
            let newIngredient = Ingredient(
                name: cleanName,
                category: category,
                amount: amount,
                unit: unit,
                iconName: iconName,
                imageData: imageData
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

    func addShoppingListItem(from recipeIngredient: RecipeIngredient, recipeName: String) {
        let cleanIngredientName = recipeIngredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanRecipeName = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanIngredientName.isEmpty, !cleanRecipeName.isEmpty else { return }

        let normalizedAmount = recipeIngredient.amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isInShoppingList(recipeIngredient, recipeName: cleanRecipeName) else { return }

        let newSource = ShoppingListSource(amountText: normalizedAmount, recipeName: cleanRecipeName)

        if let existingIndex = shoppingListItems.firstIndex(where: {
            IngredientNameMatcher.matches(storageName: $0.ingredientName, recipeName: cleanIngredientName)
        }) {
            shoppingListItems[existingIndex].sources.append(newSource)
        } else {
            shoppingListItems.append(
                ShoppingListItem(
                    ingredientName: cleanIngredientName,
                    sources: [newSource]
                )
            )
        }
        saveShoppingListItems()
    }

    func isInShoppingList(_ recipeIngredient: RecipeIngredient, recipeName: String) -> Bool {
        let cleanIngredientName = recipeIngredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanRecipeName = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = recipeIngredient.amount.trimmingCharacters(in: .whitespacesAndNewlines)

        return shoppingListItems.contains { item in
            IngredientNameMatcher.matches(storageName: item.ingredientName, recipeName: cleanIngredientName) &&
            item.sources.contains {
                $0.recipeName.localizedCaseInsensitiveCompare(cleanRecipeName) == .orderedSame &&
                $0.amountText.localizedCaseInsensitiveCompare(normalizedAmount) == .orderedSame
            }
        }
    }

    func completeShoppingListItem(_ item: ShoppingListItem) {
        let category = categoryGuess(for: item.ingredientName)

        for source in item.sources {
            let parsedAmount = parseShoppingAmount(source.amountText)
            addIngredient(
                name: item.ingredientName,
                category: category,
                amount: parsedAmount.amount,
                unit: parsedAmount.unit,
                iconName: category.categoryIcon
            )
        }

        deleteShoppingListItem(item)
    }

    func deleteShoppingListItem(_ item: ShoppingListItem) {
        shoppingListItems.removeAll { $0.id == item.id }
        saveShoppingListItems()
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

    private func saveShoppingListItems() {
        guard let data = try? JSONEncoder().encode(shoppingListItems) else { return }
        UserDefaults.standard.set(data, forKey: shoppingListKey)
    }

    private func loadShoppingListItems() -> [ShoppingListItem] {
        guard let data = UserDefaults.standard.data(forKey: shoppingListKey) else { return [] }
        return (try? JSONDecoder().decode([ShoppingListItem].self, from: data)) ?? []
    }

    private func parseShoppingAmount(_ amountText: String) -> (amount: Double, unit: UnitType) {
        let normalizedText = amountText.replacingOccurrences(of: ",", with: ".")
        let amountMatch = normalizedText.range(
            of: #"[0-9]+(\.[0-9]+)?"#,
            options: .regularExpression
        )
        let amount = amountMatch.map { Double(normalizedText[$0]) ?? 1 } ?? 1
        let lowercasedTokens = normalizedText
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)

        if lowercasedTokens.contains(where: { $0 == "kg" || $0.hasSuffix("kg") }) { return (amount, .kg) }
        if lowercasedTokens.contains(where: { $0 == "ml" || $0.hasSuffix("ml") }) { return (amount, .ml) }
        if lowercasedTokens.contains(where: { ["l", "liter", "litre", "liters", "litres"].contains($0) }) { return (amount, .liter) }
        if lowercasedTokens.contains(where: { $0 == "g" || ($0.hasSuffix("g") && Double($0.dropLast()) != nil) }) { return (amount, .g) }
        return (amount, .pcs)
    }

    private func categoryGuess(for ingredientName: String) -> IngredientCategory {
        for (categoryName, names) in commonIngredients {
            if names.contains(where: { IngredientNameMatcher.matches(storageName: $0, recipeName: ingredientName) }),
               let category = IngredientCategory(rawValue: categoryName) {
                return category
            }
        }
        return .veg
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
