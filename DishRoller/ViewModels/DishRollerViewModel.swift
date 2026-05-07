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
    @Published var selectedTime: CookingTime = .fifteen
    @Published var selectedType: DishType = .mainCourse
    @Published var selectedStyle: FlavourStyle = .chinese

    @Published var selectedResults: [Ingredient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let recipeService = OpenAIRecipeService()

    func roll(from ingredients: [Ingredient]) {
        guard !ingredients.isEmpty else {
            errorMessage = "No ingredients available. Please add ingredients first."
            return
        }

        let available = ingredients.filter(isAvailableForSelection)
        guard let random = available.randomElement() else { return }
        addSelection(random)
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

        return !selectedResults.contains {
            $0.name.lowercased() == ingredient.name.lowercased()
        }
    }

    func generateRecipe() async -> Recipe? {
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
                style: selectedStyle
            )
            isLoading = false
            return recipe
        } catch {
            isLoading = false
            errorMessage = "Failed to generate recipe. Please try again."
            return nil
        }
    }
}
