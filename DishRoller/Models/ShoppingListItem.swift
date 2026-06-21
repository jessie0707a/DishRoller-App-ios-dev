//
//  ShoppingListItem.swift
//  DishRoller
//

import Foundation

struct ShoppingListSource: Identifiable, Codable, Equatable {
    let id: UUID
    var amountText: String
    var recipeName: String

    init(id: UUID = UUID(), amountText: String, recipeName: String) {
        self.id = id
        self.amountText = amountText
        self.recipeName = recipeName
    }
}

struct ShoppingListItem: Identifiable, Codable, Equatable {
    let id: UUID
    var ingredientName: String
    var sources: [ShoppingListSource]
    var addedAt: Date
    var isCompleted: Bool
    var generatedStorageRecordIDs: [UUID]
    var editedAmountText: String?
    var selectedCategory: IngredientCategory?

    var amountText: String {
        if let editedAmountText {
            return editedAmountText
        }

        return sources
            .map { $0.amountText.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " + ")
    }

    var recipeName: String {
        var seenNames: Set<String> = []
        return sources
            .map { $0.recipeName.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seenNames.insert($0.lowercased()).inserted }
            .joined(separator: ", ")
    }

    init(
        id: UUID = UUID(),
        ingredientName: String,
        amountText: String,
        recipeName: String,
        addedAt: Date = Date(),
        isCompleted: Bool = false,
        generatedStorageRecordIDs: [UUID] = [],
        editedAmountText: String? = nil,
        selectedCategory: IngredientCategory? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.sources = [ShoppingListSource(amountText: amountText, recipeName: recipeName)]
        self.addedAt = addedAt
        self.isCompleted = isCompleted
        self.generatedStorageRecordIDs = generatedStorageRecordIDs
        self.editedAmountText = editedAmountText
        self.selectedCategory = selectedCategory
    }

    init(
        id: UUID = UUID(),
        ingredientName: String,
        sources: [ShoppingListSource],
        addedAt: Date = Date(),
        isCompleted: Bool = false,
        generatedStorageRecordIDs: [UUID] = [],
        editedAmountText: String? = nil,
        selectedCategory: IngredientCategory? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.sources = sources
        self.addedAt = addedAt
        self.isCompleted = isCompleted
        self.generatedStorageRecordIDs = generatedStorageRecordIDs
        self.editedAmountText = editedAmountText
        self.selectedCategory = selectedCategory
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ingredientName
        case sources
        case amountText
        case recipeName
        case addedAt
        case isCompleted
        case generatedStorageRecordIDs
        case editedAmountText
        case selectedCategory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ingredientName = try container.decode(String.self, forKey: .ingredientName)
        addedAt = try container.decodeIfPresent(Date.self, forKey: .addedAt) ?? Date()
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        generatedStorageRecordIDs = try container.decodeIfPresent(
            [UUID].self,
            forKey: .generatedStorageRecordIDs
        ) ?? []
        editedAmountText = try container.decodeIfPresent(String.self, forKey: .editedAmountText)
        selectedCategory = try container.decodeIfPresent(
            IngredientCategory.self,
            forKey: .selectedCategory
        )

        if let decodedSources = try container.decodeIfPresent([ShoppingListSource].self, forKey: .sources) {
            sources = decodedSources
        } else {
            let amountText = try container.decodeIfPresent(String.self, forKey: .amountText) ?? ""
            let recipeName = try container.decodeIfPresent(String.self, forKey: .recipeName) ?? ""
            sources = [ShoppingListSource(amountText: amountText, recipeName: recipeName)]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ingredientName, forKey: .ingredientName)
        try container.encode(sources, forKey: .sources)
        try container.encode(addedAt, forKey: .addedAt)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(generatedStorageRecordIDs, forKey: .generatedStorageRecordIDs)
        try container.encodeIfPresent(editedAmountText, forKey: .editedAmountText)
        try container.encodeIfPresent(selectedCategory, forKey: .selectedCategory)
    }
}
