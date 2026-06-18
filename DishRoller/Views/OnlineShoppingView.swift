//
//  OnlineShoppingView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct OnlineShoppingView: View {
    @ObservedObject var storageVM: StorageViewModel
    @State private var pendingRecoveryItem: ShoppingListItem?
    @State private var selectedShoppingItemID: UUID?

    private let shops = [
        "Woolworths Online",
        "Coles Online",
        "Asian Grocery Online"
    ]

    var body: some View {
        List {
            Section {
                if storageVM.shoppingListItems.isEmpty {
                    emptyShoppingListRow
                } else {
                    ForEach(sortedShoppingListItems) { item in
                        shoppingListRow(item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    storageVM.deleteShoppingListItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                Text("Shopping List")
            }

            Section {
                ForEach(shops, id: \.self) { shop in
                    HStack(spacing: 12) {
                        Image(systemName: "cart.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 24)

                        Text(shop)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            } header: {
                Text("Online Shopping")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Go Shopping")
        .confirmationDialog(
            "Return this item to the shopping list?",
            isPresented: Binding(
                get: { pendingRecoveryItem != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingRecoveryItem = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let item = pendingRecoveryItem {
                Button("Delete Storage Record and Recover", role: .destructive) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        storageVM.recoverShoppingListItem(item)
                    }
                    pendingRecoveryItem = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The storage record created for this purchase will be deleted, and the item will return to the active shopping list.")
        }
    }

    private var sortedShoppingListItems: [ShoppingListItem] {
        storageVM.shoppingListItems.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            return $0.addedAt < $1.addedAt
        }
    }

    private var emptyShoppingListRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.title3.weight(.bold))
                .foregroundColor(.gray)
                .frame(width: 34, height: 34)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text("No items yet")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)

                Text("Missing recipe ingredients will appear here.")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }

    private func shoppingListRow(_ item: ShoppingListItem) -> some View {
        let category = storageVM.shoppingCategory(for: item.ingredientName)
        let isSelected = selectedShoppingItemID == item.id
        let currentAmount = storageVM.shoppingListItems
            .first(where: { $0.id == item.id })?
            .amountText ?? item.amountText

        return HStack(alignment: .center, spacing: 13) {
            Button {
                if item.isCompleted {
                    pendingRecoveryItem = item
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        storageVM.completeShoppingListItem(item)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: item.isCompleted
                                ? [Color.yellow, Color.yellow]
                                : [
                                    Color.black.opacity(0.14),
                                    Color(.systemGray5),
                                    Color.white.opacity(0.72)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                .frame(width: 27, height: 27)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "Recover \(item.ingredientName)" : "Mark \(item.ingredientName) as purchased")

            ZStack {
                Circle()
                    .fill(
                        item.isCompleted
                        ? Color(.systemGray4).opacity(0.7)
                        : categoryTint(for: category).opacity(0.18)
                    )
                    .frame(width: 46, height: 46)

                Image(category.foodIconAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .grayscale(item.isCompleted ? 1 : 0)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(item.ingredientName)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(item.isCompleted ? .gray : .black)
                    .lineLimit(1)
                    .strikethrough(item.isCompleted, color: .gray)

                Text(item.recipeName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                quantityAdjustmentButton(systemName: "minus") {
                    storageVM.adjustShoppingListItemAmount(item, direction: -1)
                }
                .opacity(isSelected && !item.isCompleted ? 1 : 0)
                .allowsHitTesting(isSelected && !item.isCompleted)

                Text(currentAmount.isEmpty ? "Qty" : currentAmount)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(
                        item.isCompleted ? .gray : (isSelected ? .yellow : .black)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(width: 78, height: 38)
                    .background(
                        item.isCompleted
                        ? Color(.systemGray5)
                        : (isSelected ? Color.black : Color.yellow.opacity(0.78))
                    )
                    .clipShape(Capsule())

                quantityAdjustmentButton(systemName: "plus") {
                    storageVM.adjustShoppingListItemAmount(item, direction: 1)
                }
                .opacity(isSelected && !item.isCompleted ? 1 : 0)
                .allowsHitTesting(isSelected && !item.isCompleted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(item.isCompleted ? Color(.systemGray5).opacity(0.85) : Color.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .inset(by: isSelected ? 1.5 : 0.5)
                .stroke(
                    isSelected ? Color.yellow : Color.black.opacity(item.isCompleted ? 0.03 : 0.06),
                    style: StrokeStyle(
                        lineWidth: isSelected ? 3 : 1,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
        )
        .shadow(color: .black.opacity(item.isCompleted ? 0.02 : 0.05), radius: 10, y: 5)
        .opacity(item.isCompleted ? 0.72 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            guard !item.isCompleted else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                selectedShoppingItemID = isSelected ? nil : item.id
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.84), value: isSelected)
    }

    private func quantityAdjustmentButton(
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(Color.yellow)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func categoryTint(for category: IngredientCategory) -> Color {
        switch category {
        case .meat:
            Color(red: 0.89, green: 0.25, blue: 0.22)
        case .veg:
            Color(red: 0.16, green: 0.56, blue: 0.28)
        case .seafood:
            Color(red: 0.12, green: 0.45, blue: 0.82)
        case .drink:
            Color(red: 0.46, green: 0.36, blue: 0.88)
        case .condiment:
            Color(red: 0.86, green: 0.55, blue: 0.04)
        }
    }
}

#Preview {
    NavigationStack {
        OnlineShoppingView(storageVM: StorageViewModel())
    }
}
