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

            Image(systemName: "plus.circle")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.6))

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
        .frame(height: 150)
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    }
}
