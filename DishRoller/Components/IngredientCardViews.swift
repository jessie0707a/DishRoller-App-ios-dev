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
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.18), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Image(systemName: ingredient.category.categoryIcon)
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(.yellow)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)

            VStack(spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                    .fontWeight(.black)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(ingredient.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.yellow)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill")
                    }

                    Spacer()

                    Text("\(formatAmount(ingredient.amount)) \(ingredient.unit.rawValue)")
                        .fontWeight(.bold)
                        .font(.caption)

                    Spacer()

                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    }
}
