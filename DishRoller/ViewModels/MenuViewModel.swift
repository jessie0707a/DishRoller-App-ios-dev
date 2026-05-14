//
//  MenuViewModel.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation
import Combine

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var recipe: Recipe?
    @Published var isRegenerating = false
    @Published var regenerateError: String?

    private let recipeService = GeminiRecipeService()

    func setRecipe(_ recipe: Recipe?) {
        self.recipe = recipe
    }

    func ingredientExists(_ recipeIngredient: RecipeIngredient, storageIngredients: [Ingredient]) -> Bool {
        storageIngredients.contains {
            $0.name.lowercased() == recipeIngredient.name.lowercased()
        }
    }

    func toggleSave(recipe: Recipe, savedVM: SavedRecipesViewModel) {
        savedVM.toggleSavedState(for: recipe)
    }

    func regenerateRecipe(context: RecipeGenerationContext, avoidancePrompt: String) async -> Recipe? {
        isRegenerating = true
        regenerateError = nil
        do {
            let newRecipe = try await recipeService.generateRecipe(
                ingredients: context.ingredients,
                time: context.time,
                type: context.type,
                style: context.style,
                customPreferences: context.customPreferences,
                avoidancePrompt: avoidancePrompt
            )
            isRegenerating = false
            return newRecipe
        } catch {
            isRegenerating = false
            regenerateError = error.localizedDescription
            return nil
        }
    }
}
