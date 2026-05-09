//
//  SavedRecipesViews.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct SavedRecipesView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var recipePendingRemoval: Recipe?

    var body: some View {
        List {
            ForEach(appVM.savedRecipesVM.savedRecipes) { recipe in
                HStack(alignment: .top, spacing: 12) {
                    NavigationLink {
                        SavedRecipeDetailView(recipe: recipe)
                            .environmentObject(appVM)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title)
                                .font(.headline)
                                .foregroundColor(.black)

                            Text(recipe.estimatedTime)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            HStack {
                                ForEach(recipe.flavourTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.yellow)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        recipePendingRemoval = recipe
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.yellow)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove from favorites")
                }
            }
        }
        .navigationTitle("Saved Recipes")
        .alert(
            "Remove Saved Recipe?",
            isPresented: Binding(
                get: { recipePendingRemoval != nil },
                set: { isPresented in
                    if !isPresented {
                        recipePendingRemoval = nil
                    }
                }
            ),
            presenting: recipePendingRemoval
        ) { recipe in
            Button("Delete", role: .destructive) {
                appVM.toggleSavedState(for: recipe)
                recipePendingRemoval = nil
            }

            Button("Cancel", role: .cancel) {
                recipePendingRemoval = nil
            }
        } message: { recipe in
            Text("Delete \"\(recipe.title)\" from your saved recipes?")
        }
    }
}

private struct SavedRecipeDetailView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @State private var compareWithStorage = true

    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center) {
                    Text(recipe.title)
                        .font(.largeTitle)
                        .fontWeight(.black)

                    Spacer()

                    Button {
                        appVM.toggleSavedState(for: recipe)
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.yellow)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove from favorites")
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

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $compareWithStorage) {
                        Text("Compare with Storage")
                            .fontWeight(.black)
                    }
                    .tint(.black)

                    Text(compareWithStorage ? "Show storage match status." : "Show recipe only.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Text("Ingredient")
                    .font(.title3)
                    .fontWeight(.black)

                VStack(spacing: 14) {
                    ForEach(recipe.ingredients) { ingredient in
                        if compareWithStorage {
                            RecipeIngredientRow(
                                ingredient: ingredient,
                                exists: ingredientExists(ingredient)
                            )
                        } else {
                            HStack {
                                Text(ingredient.name)
                                    .fontWeight(.bold)

                                Spacer()

                                Text(ingredient.amount)
                                    .fontWeight(.bold)
                            }
                            .font(.title3)
                        }
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
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func ingredientExists(_ recipeIngredient: RecipeIngredient) -> Bool {
        appVM.storageVM.ingredients.contains {
            $0.name.lowercased() == recipeIngredient.name.lowercased()
        }
    }
}

#Preview {
    let appVM = AppViewModel.previewSample

    SavedRecipesView()
        .environmentObject(appVM)
}
