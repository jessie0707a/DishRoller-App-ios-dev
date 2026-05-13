//
//  RecipeIngredientRow.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct RecipeIngredientRow: View {
    private enum BadgeID {
        case amount
        case form
    }

    let ingredient: RecipeIngredient
    let exists: Bool
    var showsStorageStatus = true

    @State private var hoveredBadge: BadgeID?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(ingredient.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(2)

            HStack(spacing: 6) {
                amountBadge(title: ingredient.amount)

                if let form = ingredient.form?.nonEmpty {
                    formBadge(title: form)
                }

                if showsStorageStatus && exists {
                    statusBadge
                }

                if showsStorageStatus && !exists {
                    Button {
                        // TODO: 未來可加入 shopping list
                    } label: {
                        Image(systemName: "cart.badge.plus")
                            .font(.caption.weight(.black))
                            .foregroundColor(.black)
                            .frame(width: 34, height: 30)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add \(ingredient.name) to shopping list")
                }
            }
            .layoutPriority(0)
            .zIndex(1)
        }
        .padding(.vertical, 6)
    }

    private var statusBadge: some View {
        Image(systemName: exists ? "checkmark" : "exclamationmark")
            .font(.caption.weight(.black))
            .foregroundColor(exists ? .white : .black)
            .frame(width: 30, height: 30)
            .background(exists ? Color.black : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(exists ? "In storage" : "Missing from storage")
    }

    private func amountBadge(title: String) -> some View {
        infoBadge(
            id: .amount,
            title: title,
            maxWidth: 86,
            backgroundColor: Color.yellow.opacity(0.78),
            borderColor: Color.orange.opacity(0.38)
        )
    }

    private func formBadge(title: String) -> some View {
        infoBadge(
            id: .form,
            title: title,
            maxWidth: 78,
            backgroundColor: Color.mint.opacity(0.55),
            borderColor: Color.teal.opacity(0.35)
        )
    }

    private func infoBadge(
        id: BadgeID,
        title: String,
        maxWidth: CGFloat,
        backgroundColor: Color,
        borderColor: Color
    ) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.black)
            .foregroundColor(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.86)
            .truncationMode(.tail)
            .padding(.horizontal, 10)
            .frame(minWidth: 44, maxWidth: maxWidth, minHeight: 30)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .overlay(alignment: .top) {
                if hoveredBadge == id {
                    badgeTooltip(title)
                        .offset(y: -38)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }
            .onHover { isHovering in
                withAnimation(.easeOut(duration: 0.14)) {
                    hoveredBadge = isHovering ? id : nil
                }
            }
            .help(title)
            .accessibilityLabel(title)
    }

    private func badgeTooltip(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
            .fixedSize(horizontal: true, vertical: false)
            .allowsHitTesting(false)
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
