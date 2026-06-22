//
//  OnlineShoppingView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct OnlineShoppingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storageVM: StorageViewModel
    @State private var pendingRecoveryItem: ShoppingListItem?
    @State private var selectedShoppingItemID: UUID?
    @State private var categoryPickerItemID: UUID?
    @State private var selectedShoppingCardFrame: CGRect?

    private let shops = [
        OnlineShop(name: "Woolworths Online", url: URL(string: "https://www.woolworths.com.au/")!),
        OnlineShop(name: "Coles Online", url: URL(string: "https://www.coles.com.au/")!),
        OnlineShop(name: "Umall Asian Grocery", url: URL(string: "https://www.umall.com.au/")!)
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
                    .foregroundStyle(.black)
                    .onTapGesture(perform: clearSelection)
            }

            Section {
                ForEach(shops) { shop in
                    Link(destination: shop.url) {
                        HStack(spacing: 12) {
                            Image(systemName: "cart.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 24)

                            Text(shop.name)
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.black.opacity(0.55))
                        }
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded(clearSelection))
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            } header: {
                Text("Online Shopping")
                    .foregroundStyle(.black)
                    .onTapGesture(perform: clearSelection)
            }
        }
        .listStyle(.insetGrouped)
        .coordinateSpace(name: "shoppingListSpace")
        .onPreferenceChange(SelectedShoppingCardFrameKey.self) {
            selectedShoppingCardFrame = $0
        }
        .simultaneousGesture(
            SpatialTapGesture().onEnded { value in
                guard selectedShoppingItemID != nil,
                      let selectedShoppingCardFrame,
                      !selectedShoppingCardFrame.contains(value.location) else {
                    return
                }
                clearSelection()
            }
        )
        .scrollContentBackground(.hidden)
        .background {
            shoppingPageBackground
                .contentShape(Rectangle())
                .onTapGesture(perform: clearSelection)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            shoppingPageHeader
        }
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
        .confirmationDialog(
            "Choose Food Type",
            isPresented: Binding(
                get: { categoryPickerItemID != nil },
                set: { isPresented in
                    if !isPresented {
                        categoryPickerItemID = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            ForEach(IngredientCategory.allCases) { category in
                Button(category.displayTitle) {
                    guard let item = categoryPickerItem else { return }
                    storageVM.updateShoppingListItemCategory(item, category: category)
                    categoryPickerItemID = nil
                }
            }
            Button("Cancel", role: .cancel) {
                categoryPickerItemID = nil
            }
        }
    }

    private var shoppingPageHeader: some View {
        ZStack {
            Text("Go Shopping")
                .font(.headline.weight(.black))
                .foregroundStyle(.black)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.yellow)
                        .frame(width: 48, height: 48)
                        .background(Color.black)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 1, green: 0.82, blue: 0.05))
        .onTapGesture(perform: clearSelection)
    }

    private var shoppingPageBackground: some View {
        ZStack {
            Color(red: 1, green: 0.82, blue: 0.05)

            Image("shopping-food-pattern")
                .resizable()
                .scaledToFill()
                .opacity(0.24)

            Color.yellow.opacity(0.12)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var sortedShoppingListItems: [ShoppingListItem] {
        storageVM.shoppingListItems.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            return $0.addedAt < $1.addedAt
        }
    }

    private var categoryPickerItem: ShoppingListItem? {
        guard let categoryPickerItemID else { return nil }
        return storageVM.shoppingListItems.first { $0.id == categoryPickerItemID }
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
        let liveItem = storageVM.shoppingListItems.first(where: { $0.id == item.id }) ?? item
        let category = liveItem.selectedCategory ?? storageVM.shoppingCategory(for: item.ingredientName)
        let isSelected = selectedShoppingItemID == item.id
        let currentAmount = storageVM.shoppingListItems
            .first(where: { $0.id == item.id })?
            .amountText ?? item.amountText

        return HStack(alignment: .center, spacing: 10) {
            Button {
                if item.isCompleted {
                    pendingRecoveryItem = item
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        storageVM.completeShoppingListItem(item)
                    }
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2.weight(.bold))
                    .foregroundColor(item.isCompleted ? .yellow : .gray)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "Recover \(item.ingredientName)" : "Mark \(item.ingredientName) as purchased")

            Button {
                guard isSelected, !item.isCompleted else { return }
                categoryPickerItemID = item.id
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            item.isCompleted
                            ? Color(.systemGray4).opacity(0.7)
                            : categoryTint(for: category).opacity(0.18)
                        )
                        .frame(width: isSelected ? 58 : 44, height: isSelected ? 58 : 44)

                    Image(category.foodIconAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isSelected ? 50 : 38, height: isSelected ? 50 : 38)
                        .grayscale(item.isCompleted ? 1 : 0)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? "Change food type" : "\(category.displayTitle) food type")

            VStack(alignment: .leading, spacing: 7) {
                Text(item.ingredientName)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(item.isCompleted ? .gray : .black)
                    .lineLimit(isSelected ? nil : 2)
                    .fixedSize(horizontal: false, vertical: isSelected)
                    .strikethrough(item.isCompleted, color: .gray)

                Text(item.recipeName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .lineLimit(isSelected ? nil : 1)

                if isSelected {
                    Text(category.displayTitle)
                        .font(.caption.weight(.black))
                        .foregroundStyle(categoryTint(for: category))
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            HStack(spacing: isSelected ? 6 : 0) {
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
                    .frame(width: isSelected ? 82 : 68, height: 38)
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
        .padding(.horizontal, isSelected ? 16 : 12)
        .padding(.vertical, isSelected ? 20 : 14)
        .frame(maxWidth: .infinity, minHeight: isSelected ? 132 : 96, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(item.isCompleted ? Color(.systemGray5).opacity(0.85) : Color.white)
        )
        .background {
            if isSelected {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: SelectedShoppingCardFrameKey.self,
                        value: proxy.frame(in: .named("shoppingListSpace"))
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .inset(by: isSelected ? 1.5 : 0.5)
                .stroke(
                    isSelected
                        ? Color(red: 0.78, green: 0.52, blue: 0.02)
                        : Color.black.opacity(item.isCompleted ? 0.03 : 0.06),
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
                selectedShoppingItemID = item.id
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.84), value: isSelected)
    }

    private func clearSelection() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            selectedShoppingItemID = nil
        }
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
        case .other:
            Color(red: 0.68, green: 0.68, blue: 0.7)
        }
    }
}

private struct OnlineShop: Identifiable {
    let name: String
    let url: URL

    var id: String { name }
}

private struct SelectedShoppingCardFrameKey: PreferenceKey {
    static var defaultValue: CGRect?

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

private extension IngredientCategory {
    var displayTitle: String {
        switch self {
        case .meat: "Meat"
        case .veg: "Veg"
        case .seafood: "Seafood"
        case .drink: "Drink"
        case .condiment: "Condiment"
        case .other: "Other"
        }
    }
}

#Preview {
    NavigationStack {
        OnlineShoppingView(storageVM: StorageViewModel())
    }
}
