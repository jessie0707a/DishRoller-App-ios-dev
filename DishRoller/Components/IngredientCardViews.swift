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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryTint.opacity(0.18))
                    .frame(width: 90, height: 90)

                if let imageData = ingredient.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                } else {
                    Image(systemName: ingredient.iconName ?? ingredient.category.categoryIcon)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(categoryTint)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)

            VStack(spacing: 6) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 36)
                    .frame(maxWidth: .infinity)

                Text(ingredient.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundColor(categoryTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(categoryTint.opacity(0.12))
                    .clipShape(Capsule())

                HStack {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                    }

                    Spacer()

                    Text("\(formatAmount(ingredient.amount)) \(ingredient.unit.rawValue)")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                .foregroundColor(categoryTint)
                .frame(height: 34)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 194)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 8)
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    }

    private var categoryTint: Color {
        switch ingredient.category {
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
