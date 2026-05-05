//
//  StorageView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct StorageView: View {
    @EnvironmentObject private var appVM: AppViewModel

    @State private var itemName = ""
    @State private var amountText = ""
    @State private var selectedCategory: IngredientCategory = .meat
    @State private var selectedUnit: UnitType = .kg

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    inputPanel

                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(appVM.storageVM.filteredIngredients) { ingredient in
                            IngredientCardView(
                                ingredient: ingredient,
                                onIncrease: { appVM.storageVM.increase(ingredient) },
                                onDecrease: { appVM.storageVM.decrease(ingredient) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Color.white)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Storage")
                .font(.largeTitle)
                .fontWeight(.black)

            Spacer()

            NavigationLink {
                OnlineShoppingView()
            } label: {
                Image(systemName: "cart")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
    }

    private var inputPanel: some View {
        VStack(spacing: 18) {
            TextField("Input your purchased item", text: $itemName)
                .font(.title3)
                .padding(.horizontal, 20)
                .frame(height: 52)
                .background(Color.white)
                .clipShape(Capsule())

            HStack(spacing: 12) {
                categoryMenu
                amountField
            }

            HStack(spacing: 12) {
                unitMenu
                createButton
            }
        }
        .padding(18)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var categoryMenu: some View {
        Menu {
            ForEach(IngredientCategory.allCases) { category in
                Button(category.rawValue) {
                    selectedCategory = category
                }
            }
        } label: {
            HStack {
                Text(selectedCategory.rawValue)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 6)

                Image(systemName: "chevron.down")
            }
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.white)
            .clipShape(Capsule())
        }
    }

    private var amountField: some View {
        TextField("Amount", text: $amountText)
            .font(.headline)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.white)
            .clipShape(Capsule())
    }

    private var unitMenu: some View {
        Menu {
            ForEach(UnitType.allCases) { unit in
                Button(unit.rawValue) {
                    selectedUnit = unit
                }
            }
        } label: {
            Text(selectedUnit.rawValue)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.yellow)
                .clipShape(Capsule())
        }
    }

    private var createButton: some View {
        Button {
            let amount = Double(amountText) ?? 0
            appVM.storageVM.addIngredient(
                name: itemName,
                category: selectedCategory,
                amount: amount,
                unit: selectedUnit
            )
            itemName = ""
            amountText = ""
        } label: {
            Text("Create")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.yellow)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    StorageView()
        .environmentObject(AppViewModel())
}
