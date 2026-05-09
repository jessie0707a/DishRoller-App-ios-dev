//
//  MenuView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI
import Combine

struct MenuView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = MenuViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if let recipe = appVM.currentRecipe {
                        RecipeCardView(
                            recipe: recipe,
                            menuVM: vm,
                            storageIngredients: appVM.storageVM.ingredients
                        )
                        .environmentObject(appVM)
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack {
            Text("Today’s Menu")
                .font(.largeTitle)
                .fontWeight(.black)

            Spacer()

            NavigationLink {
                SavedRecipesView()
            } label: {
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No recipe yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Go to DishRoll and generate a recipe.")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

private struct RecipeCardView: View {
    @EnvironmentObject private var appVM: AppViewModel

    let recipe: Recipe
    let menuVM: MenuViewModel
    let storageIngredients: [Ingredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(recipe.title)
                    .font(.title)
                    .fontWeight(.black)

                Spacer()

                Button {
                    appVM.toggleSavedState(for: recipe)
                } label: {
                    Image(systemName: recipe.isSaved ? "star.fill" : "star")
                        .font(.largeTitle)
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(recipe.isSaved ? "Remove from favorites" : "Add to favorites")
            }

            HStack {
                Text("Estimated Time:")
                    .fontWeight(.black)
                Text(recipe.estimatedTime)
            }

            HStack {
                Text("Flavour:")
                    .fontWeight(.black)

                ForEach(recipe.flavourTags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }

            Text("Ingredient")
                .font(.title3)
                .fontWeight(.black)

            VStack {
                ForEach(recipe.ingredients) { ingredient in
                    RecipeIngredientRow(
                        ingredient: ingredient,
                        exists: menuVM.ingredientExists(
                            ingredient,
                            storageIngredients: storageIngredients
                        )
                    )
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            Text("Procedure")
                .font(.title3)
                .fontWeight(.black)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(recipe.procedure.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .font(.body)
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .padding()
        .background(Color.yellow)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}


#Preview {
    let appVM = AppViewModel.previewSample

    MenuView()
        .environmentObject(appVM)
}
