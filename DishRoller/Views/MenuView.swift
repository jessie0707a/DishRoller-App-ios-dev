//
//  MenuView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = MenuViewModel()
    @State private var showCongratulations = false
    @State private var showShareComingSoon = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    menuSection(
                        title: "Today’s Recipes",
                        recipes: appVM.todayMenuRecipes,
                        emptyTitle: "No recipe generated today",
                        emptyMessage: "Generate from DishRoller to add a recipe here.",
                        showsSavedIndicator: true
                    )
                    menuSection(
                        title: "Saved Recipes",
                        recipes: appVM.savedRecipesVM.savedRecipes,
                        emptyTitle: "No saved recipes",
                        emptyMessage: "Tap the star on a recipe to keep it here.",
                        showsSavedIndicator: false
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 112)
            }
            .background(pageBackground)
            .navigationBarHidden(true)
        }
        .overlay(alignment: .top) {
            if vm.isRegenerating {
                regeneratingCard
                    .padding(.top, 88)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(30)
            }
        }
        .overlay {
            if let recipe = appVM.currentRecipe {
                recipeFloatingOverlay(recipe: recipe)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: vm.isRegenerating)
        .animation(.spring(response: 0.32, dampingFraction: 0.84), value: appVM.currentRecipe?.id)
        .alert("Could not regenerate", isPresented: Binding(
            get: { vm.regenerateError != nil },
            set: { _ in vm.regenerateError = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.regenerateError ?? "")
        }
        .alert("Coming Soon", isPresented: $showShareComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Stay tuned. Soon you’ll be able to share and exchange recipes with your friends.")
        }
        .overlay {
            if showCongratulations, let recipe = appVM.currentRecipe {
                CongratulationsView(recipe: recipe, isPresented: $showCongratulations)
                    .environmentObject(appVM)
                    .zIndex(40)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Recipes")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            Button {
                showShareComingSoon = true
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)
                    .frame(width: 72, height: 48)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share recipes")
        }
    }

    private func menuSection(
        title: String,
        recipes: [Recipe],
        emptyTitle: String,
        emptyMessage: String,
        showsSavedIndicator: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)

            if recipes.isEmpty {
                emptyMenuCard(title: emptyTitle, message: emptyMessage)
            } else {
                VStack(spacing: 10) {
                    ForEach(recipes) { recipe in
                        menuSummaryCard(recipe, showsSavedIndicator: showsSavedIndicator)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: title == "Today’s Recipes" ? "sparkles" : "heart.fill")
                .font(.caption.weight(.black))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(Color.yellow)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
    }

    private func menuSummaryCard(_ recipe: Recipe, showsSavedIndicator: Bool) -> some View {
        Button {
            appVM.presentRecipe(recipe)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.headline.weight(.black))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(recipe.estimatedTime)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.gray)

                    HStack(spacing: 6) {
                        ForEach(Array(recipe.flavourTags.prefix(3)), id: \.self) { tag in
                            Text(tag)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.42))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: summaryIconName(for: recipe, showsSavedIndicator: showsSavedIndicator))
                    .font(.headline.weight(.black))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(showsSavedIndicator ? Color.clear : Color(.systemGray6))
                    .clipShape(Circle())
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func summaryIconName(for recipe: Recipe, showsSavedIndicator: Bool) -> String {
        guard showsSavedIndicator else { return "chevron.right" }
        return recipe.isSaved ? "star.fill" : "star"
    }

    private func emptyMenuCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundColor(.black)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.gray)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func recipeFloatingOverlay(recipe: Recipe) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    appVM.dismissCurrentRecipe()
                }

            GeometryReader { proxy in
                ScrollView {
                    RecipeCardView(
                        recipe: recipe,
                        menuVM: vm,
                        storageIngredients: appVM.storageVM.ingredients,
                        showsGeneratedActions: appVM.currentRecipeContext != nil,
                        onClose: {
                            appVM.dismissCurrentRecipe()
                        },
                        onLeave: {
                            appVM.dismissCurrentRecipe()
                        }
                    )
                    .environmentObject(appVM)
                    .padding(16)
                }
                .frame(width: max(proxy.size.width - 24, 0), height: max(proxy.size.height - 44, 0))
                .background(Color.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.24), radius: 24, y: 14)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .padding(.vertical, 8)
        }
    }

    private var regeneratingCard: some View {
        HStack(spacing: 14) {
            Text("Generating")
                .font(.headline.weight(.black))
                .foregroundColor(.black)

            VStack(alignment: .leading, spacing: 4) {
                Text("Generating magic...")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)

                Text("Cooking up a new recipe")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: 320)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
    }

    private var pageBackground: Color {
        Color(red: 0.96, green: 0.95, blue: 0.98)
    }
}

private struct RecipeCardView: View {
    @EnvironmentObject private var appVM: AppViewModel

    let recipe: Recipe
    let menuVM: MenuViewModel
    let storageIngredients: [Ingredient]
    let showsGeneratedActions: Bool
    let onClose: () -> Void
    let onLeave: () -> Void

    @State private var recipeRating = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text(recipe.title)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)

                Spacer()

                Button {
                    appVM.toggleSavedState(for: recipe)
                } label: {
                    Image(systemName: recipe.isSaved ? "star.fill" : "star")
                        .font(.title2.weight(.black))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(recipe.isSaved ? "Remove from favorites" : "Add to favorites")

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.black))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close recipe")
            }

            HStack {
                Text("Estimated Time:")
                    .fontWeight(.black)
                Text(recipe.estimatedTime)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Flavour")
                    .font(.headline)
                    .fontWeight(.black)

                FlavourTagFlowView(tags: recipe.flavourTags)
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
                        ),
                        isInShoppingList: appVM.storageVM.isInShoppingList(ingredient, recipeName: recipe.title),
                        onAddToShoppingList: {
                            appVM.storageVM.addShoppingListItem(from: ingredient, recipeName: recipe.title)
                        }
                    )
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Procedure")
                .font(.title3)
                .fontWeight(.black)

            ProcedureStepCardsView(steps: recipe.procedure)

            actionButtons
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if showsGeneratedActions {
            VStack(spacing: 12) {
                ratingSection

                Button {
                    saveRecipeToFavorites()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.headline.weight(.black))
                            .foregroundColor(appVM.savedRecipesVM.isSaved(recipe) ? .red : .white)
                        Text("Like it! Save to my favorites.")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.black)
                    .clipShape(Capsule())
                }

                Button {
                    onLeave()
                } label: {
                    Text("Leave")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
                }
            }
            .padding(.top, 4)
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Do you like this recipe? Please rate it.")
                .font(.headline.weight(.black))
                .foregroundColor(.black)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        recipeRating = rating
                    } label: {
                        Image(systemName: rating <= recipeRating ? "star.fill" : "star")
                            .font(.title2.weight(.black))
                            .foregroundColor(.black)
                            .frame(width: 38, height: 38)
                            .background(rating <= recipeRating ? Color.white : Color.white.opacity(0.55))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rate \(rating) stars")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func saveRecipeToFavorites() {
        guard !appVM.savedRecipesVM.isSaved(recipe) else { return }
        appVM.toggleSavedState(for: recipe)
    }
}

#Preview {
    let appVM = AppViewModel.previewSample

    MenuView()
        .environmentObject(appVM)
}
