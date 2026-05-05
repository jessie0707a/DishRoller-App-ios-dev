//
//  SavedRecipesViewModel.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation
import Combine

final class SavedRecipesViewModel: ObservableObject {
    @Published var savedRecipes: [Recipe] = []

    init() {
        savedRecipes = StorageService.shared.loadRecipes()
    }

    func saveRecipe(_ recipe: Recipe) {
        guard !isSaved(recipe) else { return }

        var saved = recipe
        saved.isSaved = true
        savedRecipes.append(saved)
        persist()
    }

    func removeRecipe(_ recipe: Recipe) {
        savedRecipes.removeAll { $0.title == recipe.title }
        persist()
    }

    func isSaved(_ recipe: Recipe) -> Bool {
        savedRecipes.contains { $0.title == recipe.title }
    }

    private func persist() {
        StorageService.shared.saveRecipes(savedRecipes)
    }
}
