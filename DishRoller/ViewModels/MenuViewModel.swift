//
//  MenuViewModel.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation
import Combine

final class MenuViewModel: ObservableObject {
    @Published var recipe: Recipe?

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
}
