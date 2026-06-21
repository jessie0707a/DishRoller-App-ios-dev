//
//  IngredientCardViews.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct IngredientCardView: View {
    let ingredient: Ingredient
    let isSelected: Bool
    let onEdit: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(ingredient.category.rawValue)
                        .font(.system(size: 13, weight: .black))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .allowsTightening(true)
                        .padding(.horizontal, 8)
                        .frame(minWidth: 66, maxWidth: 88)
                        .frame(height: 30)
                        .background(isExpired ? Color(.systemGray4) : Color.yellow)
                        .clipShape(Capsule())

                    Spacer(minLength: 2)

                    Text(expiryLabel)
                        .font(.system(size: 14, weight: .black))
                        .fontWeight(.black)
                        .foregroundColor(expiryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .allowsTightening(true)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 54, maxWidth: 82, alignment: .trailing)
                }

                itemImage

                Text(ingredient.name)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity)

                Text("\(formatAmount(ingredient.amount)) \(ingredient.unit.rawValue)")
                    .font(.system(size: 19, weight: .black))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                    .padding(.bottom, 2)
            }
            .padding(.top, 12)
            .padding(.horizontal, 10)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity)

            Button(action: onEdit) {
                ZStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 56, height: 56)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.black)
                        .offset(x: -7, y: -7)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit quantity")
            .offset(x: 17, y: 17)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 238)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .inset(by: isSelected ? 1.5 : 0)
                .stroke(
                    isSelected ? Color.yellow : Color.clear,
                    lineWidth: isSelected ? 3 : 0
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 14, y: 8)
        .animation(.spring(response: 0.28, dampingFraction: 0.84), value: isSelected)
    }

    private var itemImage: some View {
        ZStack {
            Circle()
                .fill(isExpired ? Color(.systemGray4) : categoryTint.opacity(0.18))
                .frame(width: 90, height: 90)

            if let imageData = ingredient.imageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
            } else {
                Image(cardIconAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 78)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    }

    private var cardIconAssetName: String {
        guard let iconName = ingredient.iconName,
              iconName.hasPrefix("food-category-")
        else {
            return ingredient.category.foodIconAssetName
        }

        return iconName
    }

    private var expiryLabel: String {
        guard let daysUntilExpiry else { return "No Date" }
        if daysUntilExpiry < 0 { return "Expired" }
        if daysUntilExpiry == 0 { return "Today" }
        if daysUntilExpiry == 1 { return "1 Day" }
        return "\(daysUntilExpiry) Days"
    }

    private var expiryDetailText: String {
        guard let expiryDate = ingredient.expiryDate else {
            return "Expiry date has not been set."
        }

        return "Expires \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
    }

    private var expiryTextColor: Color {
        guard let daysUntilExpiry else { return .gray }
        return daysUntilExpiry <= 1 ? Color(red: 0.89, green: 0.22, blue: 0.2) : .black
    }

    private var isExpired: Bool {
        guard let daysUntilExpiry else { return false }
        return daysUntilExpiry < 0
    }

    private var daysUntilExpiry: Int? {
        guard let expiryDate = ingredient.expiryDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDay = calendar.startOfDay(for: expiryDate)
        return calendar.dateComponents([.day], from: today, to: expiryDay).day
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
