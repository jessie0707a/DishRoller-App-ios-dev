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
        savedRecipes.removeAll { $0.id == recipe.id }
        persist()
    }

    func isSaved(_ recipe: Recipe) -> Bool {
        savedRecipes.contains { $0.id == recipe.id }
    }

    func toggleSavedState(for recipe: Recipe) {
        if isSaved(recipe) {
            removeRecipe(recipe)
        } else {
            saveRecipe(recipe)
        }
    }

    func updateImage(for recipeID: UUID, imageFileName: String) {
        guard let index = savedRecipes.firstIndex(where: { $0.id == recipeID }) else { return }
        savedRecipes[index].imageFileName = imageFileName
        persist()
    }

    func updateTitle(for recipeID: UUID, title: String) {
        guard let index = savedRecipes.firstIndex(where: { $0.id == recipeID }) else { return }
        savedRecipes[index].title = title
        persist()
    }

    private func persist() {
        StorageService.shared.saveRecipes(savedRecipes)
    }
}
