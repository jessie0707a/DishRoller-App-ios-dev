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
    @Published var isRecipeHistoryPresented = false
    @Published var isFavouriteListPresented = false
    @Published private var generatedRecipeRecords: [DailyGeneratedRecipe] = []
    @Published private var recipeCookCounts: [UUID: Int] = [:]

    @Published var storageVM = StorageViewModel()
    @Published var savedRecipesVM = SavedRecipesViewModel()
    @Published var avoidanceVM = AvoidancePreferencesViewModel()

    var todayMenuRecipes: [Recipe] {
        generatedRecipeRecords
            .filter { Calendar.current.isDateInToday($0.generatedAt) }
            .map { syncedRecipeState(for: $0.recipe) }
    }

    var recipeHistory: [DailyGeneratedRecipe] {
        generatedRecipeRecords
            .sorted { $0.generatedAt > $1.generatedAt }
            .map { record in
                DailyGeneratedRecipe(
                    recipe: syncedRecipeState(for: record.recipe),
                    generatedAt: record.generatedAt
                )
            }
    }

    var rankedFavouriteRecipes: [Recipe] {
        let savedOrder = Dictionary(
            uniqueKeysWithValues: savedRecipesVM.savedRecipes.enumerated().map {
                ($0.element.id, $0.offset)
            }
        )

        return savedRecipesVM.savedRecipes.sorted { lhs, rhs in
            let lhsCount = cookCount(for: lhs)
            let rhsCount = cookCount(for: rhs)
            if lhsCount != rhsCount {
                return lhsCount > rhsCount
            }
            return (savedOrder[lhs.id] ?? 0) < (savedOrder[rhs.id] ?? 0)
        }
    }

    private let todayMenuKey = "dishroller.todayGeneratedMenus"
    private let recipeCookCountsKey = "dishroller.recipeCookCounts"
    private var cancellables: Set<AnyCancellable> = []

    init() {
        loadTodayMenus()
        loadRecipeCookCounts()
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

    func clearRecipeHistory() {
        generatedRecipeRecords = []
        persistGeneratedRecipes()
    }

    func deleteRecipeHistoryRecord(_ record: DailyGeneratedRecipe) {
        generatedRecipeRecords.removeAll { $0.id == record.id }
        persistGeneratedRecipes()
    }

    func consumeRecipeIngredients(for recipe: Recipe) {
        for recipeIngredient in recipe.ingredients {
            storageVM.consume(recipeIngredient)
        }

        recipeCookCounts[recipe.id, default: 0] += 1
        persistRecipeCookCounts()
    }

    func cookCount(for recipe: Recipe) -> Int {
        recipeCookCounts[recipe.id, default: 0]
    }

    func regenerationContext(for recipe: Recipe) -> RecipeGenerationContext {
        if currentRecipe?.id == recipe.id, let currentRecipeContext {
            return currentRecipeContext
        }

        let ingredients = recipe.ingredients.map { recipeIngredient in
            storageVM.ingredients.first {
                IngredientNameMatcher.matches(
                    storageName: $0.name,
                    recipeName: recipeIngredient.name
                )
            } ?? Ingredient(
                name: recipeIngredient.name,
                category: storageVM.shoppingCategory(for: recipeIngredient.name),
                amount: 1,
                unit: .pcs
            )
        }

        let time = CookingTime.allCases.first {
            recipe.estimatedTime.localizedCaseInsensitiveContains($0.rawValue)
        } ?? .thirty
        let type = DishType.allCases.first { candidate in
            recipe.flavourTags.contains {
                $0.localizedCaseInsensitiveCompare(candidate.rawValue) == .orderedSame
            }
        } ?? .any
        let style = FlavourStyle.allCases.first { candidate in
            recipe.flavourTags.contains {
                $0.localizedCaseInsensitiveCompare(candidate.rawValue) == .orderedSame
            }
        } ?? .any

        return RecipeGenerationContext(
            ingredients: ingredients,
            time: time,
            type: type,
            style: style,
            customPreferences: "Create a different recipe from \(recipe.title)."
        )
    }

    func toggleSavedState(for recipe: Recipe) {
        if savedRecipesVM.isSaved(recipe) {
            savedRecipesVM.removeRecipe(recipe)
        } else {
            savedRecipesVM.saveRecipe(recipe)
        }

        let isSaved = savedRecipesVM.isSaved(recipe)
        syncGeneratedRecipeSavedState(for: recipe.id, isSaved: isSaved)

        guard var updatedCurrentRecipe = currentRecipe, updatedCurrentRecipe.id == recipe.id else { return }
        updatedCurrentRecipe.isSaved = isSaved
        currentRecipe = updatedCurrentRecipe
    }

    func updateRecipeImage(for recipeID: UUID, imageFileName: String) {
        if let index = generatedRecipeRecords.firstIndex(where: { $0.id == recipeID }) {
            generatedRecipeRecords[index].recipe.imageFileName = imageFileName
            persistGeneratedRecipes()
        }

        savedRecipesVM.updateImage(for: recipeID, imageFileName: imageFileName)

        if var updatedCurrentRecipe = currentRecipe, updatedCurrentRecipe.id == recipeID {
            updatedCurrentRecipe.imageFileName = imageFileName
            currentRecipe = updatedCurrentRecipe
        }
    }

    func updateRecipeTitle(for recipeID: UUID, title: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        if let index = generatedRecipeRecords.firstIndex(where: { $0.id == recipeID }) {
            generatedRecipeRecords[index].recipe.title = cleanTitle
            persistGeneratedRecipes()
        }

        savedRecipesVM.updateTitle(for: recipeID, title: cleanTitle)

        if var updatedCurrentRecipe = currentRecipe, updatedCurrentRecipe.id == recipeID {
            updatedCurrentRecipe.title = cleanTitle
            currentRecipe = updatedCurrentRecipe
        }
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
        generatedRecipeRecords.removeAll { $0.id == recipe.id }
        generatedRecipeRecords.insert(DailyGeneratedRecipe(recipe: recipe), at: 0)
        persistGeneratedRecipes()
    }

    private func syncGeneratedRecipeSavedState(for recipeID: UUID, isSaved: Bool) {
        guard let index = generatedRecipeRecords.firstIndex(where: { $0.id == recipeID }) else { return }
        generatedRecipeRecords[index].recipe.isSaved = isSaved
        persistGeneratedRecipes()
    }

    private func loadTodayMenus() {
        guard let data = UserDefaults.standard.data(forKey: todayMenuKey),
              let records = try? JSONDecoder().decode([DailyGeneratedRecipe].self, from: data)
        else {
            generatedRecipeRecords = []
            return
        }

        generatedRecipeRecords = records
            .map { record in
                DailyGeneratedRecipe(
                    recipe: syncedRecipeState(for: record.recipe),
                    generatedAt: record.generatedAt
                )
            }
            .sorted { $0.generatedAt > $1.generatedAt }
        persistGeneratedRecipes()
    }

    private func persistGeneratedRecipes() {
        guard let data = try? JSONEncoder().encode(generatedRecipeRecords) else { return }
        UserDefaults.standard.set(data, forKey: todayMenuKey)
    }

    private func loadRecipeCookCounts() {
        guard let data = UserDefaults.standard.data(forKey: recipeCookCountsKey),
              let storedCounts = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            recipeCookCounts = [:]
            return
        }

        recipeCookCounts = Dictionary(
            uniqueKeysWithValues: storedCounts.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, value)
            }
        )
    }

    private func persistRecipeCookCounts() {
        let storedCounts = Dictionary(
            uniqueKeysWithValues: recipeCookCounts.map { ($0.key.uuidString, $0.value) }
        )
        guard let data = try? JSONEncoder().encode(storedCounts) else { return }
        UserDefaults.standard.set(data, forKey: recipeCookCountsKey)
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
