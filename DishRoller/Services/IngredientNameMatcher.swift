//
//  IngredientNameMatcher.swift
//  DishRoller
//

import Foundation

enum IngredientNameMatcher {
    static func matches(storageName: String, recipeName: String) -> Bool {
        let storageTokens = normalizedTokens(from: storageName)
        let recipeTokens = normalizedTokens(from: recipeName)

        guard !storageTokens.isEmpty, !recipeTokens.isEmpty else { return false }

        if storageTokens == recipeTokens { return true }
        if storageTokens.isSubset(of: recipeTokens) { return true }
        if recipeTokens.isSubset(of: storageTokens) { return true }

        let storagePhrase = storageTokens.sorted().joined(separator: " ")
        let recipePhrase = recipeTokens.sorted().joined(separator: " ")
        return storagePhrase.contains(recipePhrase) || recipePhrase.contains(storagePhrase)
    }

    private static func normalizedTokens(from name: String) -> Set<String> {
        let separators = CharacterSet.alphanumerics.inverted
        let descriptorWords: Set<String> = [
            "fresh", "frozen", "dried", "dry", "raw", "cooked", "minced", "ground",
            "chopped", "sliced", "diced", "crushed", "grated", "whole", "boneless",
            "skinless", "lean", "organic"
        ]

        return Set(
            name
                .lowercased()
                .components(separatedBy: separators)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !descriptorWords.contains($0) }
        )
    }
}
