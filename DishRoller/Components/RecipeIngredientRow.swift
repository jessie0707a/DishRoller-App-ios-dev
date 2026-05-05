//
//  RecipeIngredientRow.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct RecipeIngredientRow: View {
    let ingredient: RecipeIngredient
    let exists: Bool

    var body: some View {
        HStack {
            Image(systemName: exists ? "checkmark.circle.fill" : "circle")
                .foregroundColor(exists ? .black : .black)

            Text(ingredient.name)
                .fontWeight(.bold)

            Spacer()

            Text(ingredient.amount)
                .fontWeight(.bold)

            if !exists {
                Button {
                    // TODO: 未來可加入 shopping list
                } label: {
                    Image(systemName: "cart.badge.plus")
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                }
            }
        }
        .font(.title3)
    }
}
