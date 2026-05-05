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

        guard selectedResults.count < 5 else { return }

        let available = ingredients.filter { ingredient in
            !selectedResults.contains(where: { $0.name.lowercased() == ingredient.name.lowercased() })
        }

        guard let random = available.randomElement() else { return }
        selectedResults.append(random)
    }

    func removeResult(_ ingredient: Ingredient) {
        selectedResults.removeAll { $0.id == ingredient.id }
    }

    func clearResults() {
        selectedResults.removeAll()
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
