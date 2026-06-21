//
//  DishRollerViewModel.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation
import Combine

@MainActor
final class DishRollerViewModel: ObservableObject {
    var selectedTime: CookingTime = .fifteen
    var selectedType: DishType = .mainCourse
    var selectedStyle: FlavourStyle = .chinese

    @Published var selectedResults: [Ingredient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let recipeService = GeminiRecipeService()

    func roll(from ingredients: [Ingredient]) {
        guard !ingredients.isEmpty else {
            errorMessage = "No ingredients available. Please add ingredients first."
            return
        }

        let available = selectableIngredients(from: ingredients)
        guard let random = available.randomElement() else {
            errorMessage = "No available ingredients match the current selection."
            return
        }
        addSelection(random)
    }

    func selectableIngredients(
        from ingredients: [Ingredient],
        matching categories: Set<IngredientCategory>? = nil
    ) -> [Ingredient] {
        var seenNames: Set<String> = []

        return ingredients
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            .filter { ingredient in
                guard ingredient.amount > 0 else { return false }
                if let categories, !categories.contains(ingredient.category) { return false }
                return isAvailableForSelection(ingredient)
            }
            .filter { ingredient in
                let key = selectionKey(for: ingredient)
                guard !seenNames.contains(key) else { return false }
                seenNames.insert(key)
                return true
            }
    }

    func addSelection(_ ingredient: Ingredient) {
        guard isAvailableForSelection(ingredient) else { return }
        selectedResults.append(ingredient)
    }

    func removeResult(_ ingredient: Ingredient) {
        selectedResults.removeAll { $0.id == ingredient.id }
    }

    func clearResults() {
        selectedResults.removeAll()
    }

    private func isAvailableForSelection(_ ingredient: Ingredient) -> Bool {
        guard selectedResults.count < 5 else { return false }
        guard ingredient.amount > 0 else { return false }

        let key = selectionKey(for: ingredient)
        return !selectedResults.contains { selectionKey(for: $0) == key }
    }

    private func selectionKey(for ingredient: Ingredient) -> String {
        ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func generateRecipe(avoidancePrompt: String) async -> Recipe? {
        guard !selectedResults.isEmpty else {
            errorMessage = "Please select at least one ingredient."
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            let recipe = try await recipeService.generateRecipe(
                ingredients: selectedResults,
                time: selectedTime,
                type: selectedType,
                style: selectedStyle,
                customPreferences: "",
                avoidancePrompt: avoidancePrompt
            )
            isLoading = false
            return recipe
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
