//
//  AppViewModel.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Combine
import Foundation

final class AppViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var currentRecipe: Recipe?

    @Published var storageVM = StorageViewModel()
    @Published var savedRecipesVM = SavedRecipesViewModel()

    func openMenu(with recipe: Recipe) {
        currentRecipe = recipe
        selectedTab = 2
    }
}
