//
//  AppViewModel.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Combine
import Foundation

struct RecipeGenerationContext {
    var ingredients: [Ingredient]
    var time: CookingTime
    var type: DishType
    var style: FlavourStyle
    var customPreferences: String
}

struct DailyGeneratedRecipe: Identifiable, Codable, Equatable {
    let id: UUID
    var recipe: Recipe
    var generatedAt: Date

    init(recipe: Recipe, generatedAt: Date = Date()) {
        self.id = recipe.id
        self.recipe = recipe
        self.generatedAt = generatedAt
    }
}

final class AppViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var currentRecipe: Recipe?
    @Published var currentRecipeContext: RecipeGenerationContext?
    @Published private var todayMenuRecords: [DailyGeneratedRecipe] = []

    @Published var storageVM = StorageViewModel()
    @Published var savedRecipesVM = SavedRecipesViewModel()
    @Published var avoidanceVM = AvoidancePreferencesViewModel()

    var todayMenuRecipes: [Recipe] {
        todayMenuRecords.map { syncedRecipeState(for: $0.recipe) }
    }

    private let todayMenuKey = "dishroller.todayGeneratedMenus"
    private var cancellables: Set<AnyCancellable> = []

    init() {
        loadTodayMenus()
        bindChildViewModels()
    }

    func openMenu(with recipe: Recipe, context: RecipeGenerationContext? = nil) {
        let syncedRecipe = syncedRecipeState(for: recipe)
        addTodayMenuRecipe(syncedRecipe)
        currentRecipe = syncedRecipe
        currentRecipeContext = context
        selectedTab = 2
    }

    func presentRecipe(_ recipe: Recipe, context: RecipeGenerationContext? = nil) {
        currentRecipe = syncedRecipeState(for: recipe)
        currentRecipeContext = context
        selectedTab = 2
    }

    func dismissCurrentRecipe() {
        currentRecipe = nil
        currentRecipeContext = nil
    }

    func consumeRecipeIngredients(for recipe: Recipe) {
        for recipeIngredient in recipe.ingredients {
            guard let match = storageVM.ingredients.first(where: {
                IngredientNameMatcher.matches(storageName: $0.name, recipeName: recipeIngredient.name)
            }) else { continue }
            storageVM.decrease(match)
        }
    }

    func toggleSavedState(for recipe: Recipe) {
        if savedRecipesVM.isSaved(recipe) {
            savedRecipesVM.removeRecipe(recipe)
        } else {
            savedRecipesVM.saveRecipe(recipe)
        }

        let isSaved = savedRecipesVM.isSaved(recipe)
        syncTodayMenuSavedState(for: recipe.id, isSaved: isSaved)

        guard var updatedCurrentRecipe = currentRecipe, updatedCurrentRecipe.id == recipe.id else { return }
        updatedCurrentRecipe.isSaved = isSaved
        currentRecipe = updatedCurrentRecipe
    }

    private func bindChildViewModels() {
        storageVM.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        savedRecipesVM.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        avoidanceVM.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func addTodayMenuRecipe(_ recipe: Recipe) {
        pruneExpiredTodayMenus()
        todayMenuRecords.removeAll { $0.id == recipe.id }
        todayMenuRecords.insert(DailyGeneratedRecipe(recipe: recipe), at: 0)
        persistTodayMenus()
    }

    private func syncTodayMenuSavedState(for recipeID: UUID, isSaved: Bool) {
        guard let index = todayMenuRecords.firstIndex(where: { $0.id == recipeID }) else { return }
        todayMenuRecords[index].recipe.isSaved = isSaved
        persistTodayMenus()
    }

    private func loadTodayMenus() {
        guard let data = UserDefaults.standard.data(forKey: todayMenuKey),
              let records = try? JSONDecoder().decode([DailyGeneratedRecipe].self, from: data)
        else {
            todayMenuRecords = []
            return
        }

        todayMenuRecords = records
            .filter { Calendar.current.isDateInToday($0.generatedAt) }
            .map { record in
                DailyGeneratedRecipe(
                    recipe: syncedRecipeState(for: record.recipe),
                    generatedAt: record.generatedAt
                )
            }
        persistTodayMenus()
    }

    private func pruneExpiredTodayMenus() {
        todayMenuRecords = todayMenuRecords.filter { Calendar.current.isDateInToday($0.generatedAt) }
        persistTodayMenus()
    }

    private func persistTodayMenus() {
        guard let data = try? JSONEncoder().encode(todayMenuRecords) else { return }
        UserDefaults.standard.set(data, forKey: todayMenuKey)
    }

    private func syncedRecipeState(for recipe: Recipe) -> Recipe {
        var updatedRecipe = recipe
        updatedRecipe.isSaved = savedRecipesVM.isSaved(recipe)
        return updatedRecipe
    }
}

#if DEBUG
extension AppViewModel {
    static var previewSample: AppViewModel {
        let appVM = AppViewModel()

        appVM.storageVM.ingredients = [
            Ingredient(name: "Chicken Thigh", category: .meat, amount: 2, unit: .pcs),
            Ingredient(name: "Garlic", category: .veg, amount: 3, unit: .pcs),
            Ingredient(name: "Soy Sauce", category: .condiment, amount: 150, unit: .ml),
            Ingredient(name: "Broccoli", category: .veg, amount: 1, unit: .pcs)
        ]

        let sampleRecipe = Recipe(
            title: "Black Pepper Garlic Chicken",
            estimatedTime: "30 min",
            flavourTags: ["Chinese", "Savory", "Quick"],
            ingredients: [
                RecipeIngredient(name: "Chicken Thigh", amount: "2 pcs", form: "sliced"),
                RecipeIngredient(name: "Garlic", amount: "3 cloves", form: "minced"),
                RecipeIngredient(name: "Soy Sauce", amount: "2 tbsp", form: "sauce"),
                RecipeIngredient(name: "Black Pepper", amount: "1 tsp", form: "ground")
            ],
            procedure: [
                "Marinate the chicken with soy sauce and black pepper for 10 minutes.",
                "Saute garlic until fragrant, then add chicken and sear both sides.",
                "Cook until the chicken is done, then reduce the sauce slightly before serving."
            ],
            isSaved: true
        )

        appVM.savedRecipesVM.savedRecipes = [sampleRecipe]
        appVM.openMenu(with: sampleRecipe)

        return appVM
    }
}
#endif
