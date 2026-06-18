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
        aggregatedIngredients
            .filter { ingredient in
                let matchesCategory = selectedFilter == nil || ingredient.category == selectedFilter
                let matchesSearch = searchText.isEmpty || ingredient.name.localizedCaseInsensitiveContains(searchText)
                return matchesCategory && matchesSearch
            }
            .sorted(by: storageCardSort)
    }

    private var aggregatedIngredients: [Ingredient] {
        var groupedRecords: [String: [Ingredient]] = [:]
        var orderedKeys: [String] = []

        for ingredient in ingredients where ingredient.amount > 0 {
            let key = aggregateKey(for: ingredient)
            if groupedRecords[key] == nil {
                orderedKeys.append(key)
                groupedRecords[key] = []
            }
            groupedRecords[key]?.append(ingredient)
        }

        return orderedKeys.compactMap { key in
            guard let records = groupedRecords[key],
                  let displayRecord = earliestRecord(in: records) ?? records.first else {
                return nil
            }

            let totalAmount = records.reduce(0) { $0 + $1.amount }
            return Ingredient(
                id: displayRecord.id,
                name: displayRecord.name,
                category: displayRecord.category,
                amount: totalAmount,
                unit: displayRecord.unit,
                iconName: displayRecord.iconName ?? displayRecord.category.foodIconAssetName,
                imageData: displayRecord.imageData,
                expiryDate: earliestExpiryDate(forIngredientNamed: displayRecord.name)
            )
        }
    }

    private func storageCardSort(_ first: Ingredient, _ second: Ingredient) -> Bool {
        switch (first.expiryDate, second.expiryDate) {
        case let (firstDate?, secondDate?):
            let firstDay = Calendar.current.startOfDay(for: firstDate)
            let secondDay = Calendar.current.startOfDay(for: secondDate)
            if firstDay != secondDay {
                return firstDay < secondDay
            }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }

        let firstCategoryIndex = categorySortIndex(for: first.category)
        let secondCategoryIndex = categorySortIndex(for: second.category)
        if firstCategoryIndex != secondCategoryIndex {
            return firstCategoryIndex < secondCategoryIndex
        }

        return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
    }

    private func categorySortIndex(for category: IngredientCategory) -> Int {
        IngredientCategory.allCases.firstIndex(where: { $0 == category }) ?? Int.max
    }

    func addIngredient(
        name: String,
        category: IngredientCategory,
        amount: Double,
        unit: UnitType,
        iconName: String? = nil,
        imageData: Data? = nil,
        expiryDate: Date? = nil
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
            if let expiryDate {
                ingredients[index].expiryDate = expiryDate
            }
        } else {
            let newIngredient = Ingredient(
                name: cleanName,
                category: category,
                amount: amount,
                unit: unit,
                iconName: iconName,
                imageData: imageData,
                expiryDate: expiryDate
            )
            ingredients.append(newIngredient)
        }

        save()
    }

    @discardableResult
    func addIngredientRecord(
        name: String,
        category: IngredientCategory,
        amount: Double,
        unit: UnitType,
        iconName: String? = nil,
        imageData: Data? = nil,
        expiryDate: Date? = nil
    ) -> Ingredient? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, amount > 0 else { return nil }

        let newIngredient = Ingredient(
            name: cleanName,
            category: category,
            amount: amount,
            unit: unit,
            iconName: iconName,
            imageData: imageData,
            expiryDate: expiryDate
        )
        ingredients.append(newIngredient)
        save()
        return newIngredient
    }

    func matchingPurchaseRecords(for ingredient: Ingredient) -> [Ingredient] {
        ingredients
            .filter {
                $0.amount > 0 &&
                $0.category == ingredient.category &&
                $0.unit == ingredient.unit &&
                $0.name.localizedCaseInsensitiveCompare(ingredient.name) == .orderedSame
            }
    }

    func updateIngredientRecord(
        id: UUID,
        name: String,
        amount: Double,
        unit: UnitType,
        expiryDate: Date?
    ) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty,
              amount >= 0,
              let index = ingredients.firstIndex(where: { $0.id == id }) else { return }
        if amount == 0 {
            ingredients.remove(at: index)
            save()
            return
        }

        ingredients[index].name = cleanName
        ingredients[index].amount = amount
        ingredients[index].unit = unit
        ingredients[index].expiryDate = expiryDate
        save()
    }

    private func aggregateKey(for ingredient: Ingredient) -> String {
        [
            normalizedIngredientName(ingredient.name),
            ingredient.category.rawValue,
            ingredient.unit.rawValue
        ].joined(separator: "|")
    }

    private func earliestRecord(in records: [Ingredient]) -> Ingredient? {
        records
            .filter { $0.amount > 0 && $0.expiryDate != nil }
            .min {
                guard let firstDate = $0.expiryDate, let secondDate = $1.expiryDate else { return false }
                return firstDate < secondDate
            }
    }

    private func earliestExpiryDate(forIngredientNamed name: String) -> Date? {
        let normalizedName = normalizedIngredientName(name)
        return ingredients
            .filter { $0.amount > 0 && normalizedIngredientName($0.name) == normalizedName }
            .compactMap(\.expiryDate)
            .min()
    }

    private func normalizedIngredientName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
            shoppingListItems[existingIndex].editedAmountText = nil
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
        guard let index = shoppingListItems.firstIndex(where: { $0.id == item.id }) else { return }
        guard !shoppingListItems[index].isCompleted else { return }

        let category = shoppingCategory(for: item.ingredientName)
        var generatedRecordIDs: [UUID] = []
        let purchaseAmounts: [String]

        if item.editedAmountText != nil {
            purchaseAmounts = [item.amountText]
        } else {
            purchaseAmounts = item.sources.map(\.amountText)
        }

        for amountText in purchaseAmounts {
            let parsedAmount = parseShoppingAmount(amountText)
            if let record = addIngredientRecord(
                name: item.ingredientName,
                category: category,
                amount: parsedAmount.amount,
                unit: parsedAmount.unit,
                iconName: category.foodIconAssetName
            ) {
                generatedRecordIDs.append(record.id)
            }
        }

        shoppingListItems[index].generatedStorageRecordIDs = generatedRecordIDs
        shoppingListItems[index].isCompleted = true
        saveShoppingListItems()
    }

    func updateShoppingListItemAmount(_ item: ShoppingListItem, amountText: String) {
        guard let index = shoppingListItems.firstIndex(where: { $0.id == item.id }),
              !shoppingListItems[index].isCompleted else {
            return
        }

        shoppingListItems[index].editedAmountText = amountText
        saveShoppingListItems()
    }

    func adjustShoppingListItemAmount(_ item: ShoppingListItem, direction: Int) {
        guard direction != 0,
              let index = shoppingListItems.firstIndex(where: { $0.id == item.id }),
              !shoppingListItems[index].isCompleted else {
            return
        }

        let currentAmount = parseShoppingAmount(shoppingListItems[index].amountText)
        let increment = step(for: currentAmount.unit)
        let adjustedAmount = max(increment, currentAmount.amount + (Double(direction) * increment))
        let formattedAmount = adjustedAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(adjustedAmount))
            : String(format: "%.1f", adjustedAmount)

        shoppingListItems[index].editedAmountText = "\(formattedAmount) \(currentAmount.unit.rawValue)"
        saveShoppingListItems()
    }

    func recoverShoppingListItem(_ item: ShoppingListItem) {
        guard let index = shoppingListItems.firstIndex(where: { $0.id == item.id }) else { return }

        let generatedIDs = Set(shoppingListItems[index].generatedStorageRecordIDs)
        if !generatedIDs.isEmpty {
            ingredients.removeAll { generatedIDs.contains($0.id) }
            save()
        }

        shoppingListItems[index].generatedStorageRecordIDs = []
        shoppingListItems[index].isCompleted = false
        saveShoppingListItems()
    }

    func shoppingCategory(for ingredientName: String) -> IngredientCategory {
        categoryGuess(for: ingredientName)
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
        let calendar = Calendar.current
        ingredients = [
            Ingredient(name: "Lamb", category: .meat, amount: 1.6, unit: .kg, expiryDate: calendar.date(byAdding: .day, value: 3, to: Date())),
            Ingredient(name: "Pork", category: .meat, amount: 1.6, unit: .kg, expiryDate: calendar.date(byAdding: .day, value: 1, to: Date())),
            Ingredient(name: "Chicken", category: .meat, amount: 1.6, unit: .kg, expiryDate: calendar.date(byAdding: .day, value: 4, to: Date())),
            Ingredient(name: "Beef", category: .meat, amount: 1.6, unit: .kg, expiryDate: calendar.date(byAdding: .day, value: -1, to: Date())),
            Ingredient(name: "Pepper", category: .condiment, amount: 150, unit: .g, expiryDate: calendar.date(byAdding: .day, value: 30, to: Date())),
            Ingredient(name: "Soy Sauce", category: .condiment, amount: 1.5, unit: .liter, expiryDate: calendar.date(byAdding: .day, value: 60, to: Date())),
            Ingredient(name: "Coriander", category: .veg, amount: 500, unit: .g, expiryDate: calendar.date(byAdding: .day, value: 2, to: Date())),
            Ingredient(name: "Shrimp", category: .seafood, amount: 500, unit: .g, expiryDate: calendar.date(byAdding: .day, value: 1, to: Date())),
            Ingredient(name: "Milk", category: .drink, amount: 2, unit: .liter, expiryDate: calendar.date(byAdding: .day, value: 6, to: Date()))
        ]
        save()
    }
}
