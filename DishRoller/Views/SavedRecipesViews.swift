//
//  SavedRecipesViews.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct SavedRecipesView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        List {
            ForEach(appVM.savedRecipesVM.savedRecipes) { recipe in
                Button {
                    appVM.currentRecipe = recipe
                    appVM.selectedTab = 2
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
                }
            }
        }
        .navigationTitle("Saved Recipes")
    }
}

#Preview {
    SavedRecipesView()
        .environmentObject(AppViewModel())
}

