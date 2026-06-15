//
//  OnlineShoppingView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct OnlineShoppingView: View {
    @ObservedObject var storageVM: StorageViewModel

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
                    ForEach(storageVM.shoppingListItems) { item in
                        shoppingListRow(item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    storageVM.completeShoppingListItem(item)
                                } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
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
                }
            } header: {
                Text("Online Shopping")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Go Shopping")
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "basket.fill")
                .font(.headline.weight(.black))
                .foregroundColor(.black)
                .frame(width: 38, height: 38)
                .background(Color.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 8) {
                Text(item.ingredientName)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .lineLimit(1)

                Text(item.amountText.isEmpty ? "Amount not set" : item.amountText)
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(item.recipeName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
}

#Preview {
    NavigationStack {
        OnlineShoppingView(storageVM: StorageViewModel())
    }
}
