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
    @State private var showCongratulations = false
    @State private var cookedRecipeName: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if let recipe = appVM.currentRecipe {
                        RecipeCardView(
                            recipe: recipe,
                            menuVM: vm,
                            storageIngredients: appVM.storageVM.ingredients,
                            onFinished: {
                                appVM.consumeRecipeIngredients(for: recipe)
                                cookedRecipeName = recipe.title
                                showCongratulations = true
                            },
                            onRegenerate: {
                                guard let context = appVM.currentRecipeContext else { return }
                                if let newRecipe = await vm.regenerateRecipe(
                                    context: context,
                                    avoidancePrompt: appVM.avoidanceVM.selectedAvoidancePrompt
                                ) {
                                    appVM.currentRecipe = newRecipe
                                }
                            }
                        )
                        .environmentObject(appVM)
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showCongratulations) {
                CongratulationsView(recipeName: cookedRecipeName)
                    .environmentObject(appVM)
            }
        }
        .overlay(alignment: .top) {
            if vm.isRegenerating {
                regeneratingCard
                    .padding(.top, 88)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: vm.isRegenerating)
        .alert("Could not regenerate", isPresented: Binding(
            get: { vm.regenerateError != nil },
            set: { _ in vm.regenerateError = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.regenerateError ?? "")
        }
    }

    private var regeneratingCard: some View {
        HStack(spacing: 14) {
            Text("🪄")
                .font(.system(size: 34))

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
    let onFinished: () -> Void
    let onRegenerate: () async -> Void

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

            ProcedureStepCardsView(steps: recipe.procedure)

            actionButtons
        }
        .padding()
        .background(Color.yellow)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onFinished()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.black))
                    Text("Finished!")
                        .font(.headline)
                        .fontWeight(.black)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.black)
                .clipShape(Capsule())
            }
            .disabled(menuVM.isRegenerating)

            Button {
                Task { await onRegenerate() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline.weight(.black))
                    Text("Regenerate")
                        .font(.headline)
                        .fontWeight(.black)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
            }
            .disabled(menuVM.isRegenerating || appVM.currentRecipeContext == nil)
        }
        .padding(.top, 4)
    }
}


#Preview {
    let appVM = AppViewModel.previewSample

    MenuView()
        .environmentObject(appVM)
}
