//
//  StorageService.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation
import SwiftData

final class StorageService {
    static let shared = StorageService()

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    private let legacyIngredientsKey = "dishroller.ingredients"
    private let legacySavedRecipesKey = "dishroller.savedRecipes"
    private let legacyAvoidanceProfilesKey = "dishroller.avoidanceProfiles"

    private init() {
        do {
            modelContainer = try ModelContainer(
                for: StoredIngredientRecord.self,
                StoredRecipeRecord.self,
                StoredAvoidanceProfileRecord.self
            )
            modelContext = ModelContext(modelContainer)
            migrateLegacyUserDefaultsDataIfNeeded()
        } catch {
            fatalError("Failed to initialize SwiftData storage: \(error)")
        }
    }

    func saveIngredients(_ ingredients: [Ingredient]) {
        syncRecords(
            incomingValues: ingredients,
            fetch: fetchIngredientRecords,
            id: { $0.id },
            insert: { ingredient, orderIndex in
                modelContext.insert(StoredIngredientRecord(ingredient: ingredient, orderIndex: orderIndex))
            },
            update: { record, ingredient, orderIndex in
                record.update(from: ingredient, orderIndex: orderIndex)
            }
        )
    }

    func loadIngredients() -> [Ingredient] {
        fetchIngredientRecords().map { $0.toIngredient() }
    }

    func saveRecipes(_ recipes: [Recipe]) {
        syncRecords(
            incomingValues: recipes,
            fetch: fetchRecipeRecords,
            id: { $0.id },
            insert: { recipe, orderIndex in
                modelContext.insert(StoredRecipeRecord(recipe: recipe, orderIndex: orderIndex))
            },
            update: { record, recipe, orderIndex in
                record.update(from: recipe, orderIndex: orderIndex)
            }
        )
    }

    func loadRecipes() -> [Recipe] {
        fetchRecipeRecords().map { $0.toRecipe() }
    }

    func saveAvoidanceProfiles(_ profiles: [AvoidanceProfile]) {
        syncRecords(
            incomingValues: profiles,
            fetch: fetchAvoidanceProfileRecords,
            id: { $0.id },
            insert: { profile, orderIndex in
                modelContext.insert(StoredAvoidanceProfileRecord(profile: profile, orderIndex: orderIndex))
            },
            update: { record, profile, orderIndex in
                record.update(from: profile, orderIndex: orderIndex)
            }
        )
    }

    func loadAvoidanceProfiles() -> [AvoidanceProfile] {
        fetchAvoidanceProfileRecords().map { $0.toProfile() }
    }

    private func fetchIngredientRecords() -> [StoredIngredientRecord] {
        let descriptor = FetchDescriptor<StoredIngredientRecord>(sortBy: [SortDescriptor(\.orderIndex)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchRecipeRecords() -> [StoredRecipeRecord] {
        let descriptor = FetchDescriptor<StoredRecipeRecord>(sortBy: [SortDescriptor(\.orderIndex)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchAvoidanceProfileRecords() -> [StoredAvoidanceProfileRecord] {
        let descriptor = FetchDescriptor<StoredAvoidanceProfileRecord>(sortBy: [SortDescriptor(\.orderIndex)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func syncRecords<Value, Record>(
        incomingValues: [Value],
        fetch: () -> [Record],
        id: (Value) -> UUID,
        insert: (Value, Int) -> Void,
        update: (Record, Value, Int) -> Void
    ) where Record: PersistentModel & Identifiable, Record.ID == UUID {
        let existingRecords = fetch()
        let existingByID = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })
        var incomingIDs = Set<UUID>()

        for (orderIndex, value) in incomingValues.enumerated() {
            let valueID = id(value)
            incomingIDs.insert(valueID)

            if let record = existingByID[valueID] {
                update(record, value, orderIndex)
            } else {
                insert(value, orderIndex)
            }
        }

        for record in existingRecords where !incomingIDs.contains(record.id) {
            modelContext.delete(record)
        }

        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("SwiftData save failed: \(error)")
        }
    }

    private func migrateLegacyUserDefaultsDataIfNeeded() {
        migrateLegacyValues(
            key: legacyIngredientsKey,
            type: [Ingredient].self,
            hasSwiftDataRecords: { !fetchIngredientRecords().isEmpty },
            save: saveIngredients
        )

        migrateLegacyValues(
            key: legacySavedRecipesKey,
            type: [Recipe].self,
            hasSwiftDataRecords: { !fetchRecipeRecords().isEmpty },
            save: saveRecipes
        )

        migrateLegacyValues(
            key: legacyAvoidanceProfilesKey,
            type: [AvoidanceProfile].self,
            hasSwiftDataRecords: { !fetchAvoidanceProfileRecords().isEmpty },
            save: saveAvoidanceProfiles
        )
    }

    private func migrateLegacyValues<Value: Decodable>(
        key: String,
        type: Value.Type,
        hasSwiftDataRecords: () -> Bool,
        save: (Value) -> Void
    ) {
        guard !hasSwiftDataRecords(),
              let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode(type, from: data)
        else {
            return
        }

        save(value)
        UserDefaults.standard.removeObject(forKey: key)
    }
}
