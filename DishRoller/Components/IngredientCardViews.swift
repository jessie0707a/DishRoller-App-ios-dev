//
//  IngredientCardViews.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct IngredientCardView: View {
    let ingredient: Ingredient
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)

            groceryLineArt
                .foregroundColor(.black.opacity(0.1))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.top, 20)
                .allowsHitTesting(false)

            VStack(spacing: 8) {
                Text(ingredient.category.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Text(ingredient.name)
                    .font(.headline)
                    .fontWeight(.black)
                    .lineLimit(1)

                HStack {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill")
                    }

                    Spacer()

                    Text("\(formatAmount(ingredient.amount)) \(ingredient.unit.rawValue)")
                        .fontWeight(.bold)

                    Spacer()

                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.yellow)
            }
            .padding(.top, 8)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var groceryLineArt: some View {
        switch ingredient.category {
        case .meat:
            categoryIcon("fork.knife")
        case .veg:
            categoryIcon("carrot")
        case .seafood:
            categoryIcon("fish")
        case .drink:
            categoryIcon("cup.and.saucer")
        case .condiment:
            categoryIcon("takeoutbag.and.cup.and.straw")
        }
    }

    private func categoryIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 64, weight: .light))
            .symbolRenderingMode(.monochrome)
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    }
}
