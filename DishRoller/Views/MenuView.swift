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
    @State private var selectedTodayRecipeIndex = 0
    @GestureState private var todayCarouselDrag: CGFloat = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    todayRecipesSection
                    menuSection(
                        title: "Favourite",
                        recipes: Array(appVM.rankedFavouriteRecipes.prefix(10)),
                        emptyTitle: "No favourite recipes",
                        emptyMessage: "Tap the star on a recipe to keep it here.",
                        showsSavedIndicator: false,
                        showsCookCount: true,
                        showsMoreButton: !appVM.savedRecipesVM.savedRecipes.isEmpty
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
        .fullScreenCover(item: $appVM.currentRecipe) { recipe in
            recipeFullPage(recipe: recipe)
                .interactiveDismissDisabled()
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
        .overlay {
            if showCongratulations, let recipe = appVM.currentRecipe {
                CongratulationsView(recipe: recipe, isPresented: $showCongratulations)
                    .environmentObject(appVM)
                    .zIndex(40)
            }
        }
        .overlay {
            if appVM.isRecipeHistoryPresented {
                RecipeHistoryView(
                    records: appVM.recipeHistory,
                    onBack: {
                        closeHistory()
                    },
                    onClear: {
                        appVM.clearRecipeHistory()
                    },
                    onSelect: { recipe in
                        closeHistory(opening: recipe)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .trailing))
                .zIndex(50)
            }
        }
        .overlay {
            if appVM.isFavouriteListPresented {
                FavouriteRecipesView(
                    recipes: appVM.rankedFavouriteRecipes,
                    cookCount: appVM.cookCount,
                    onBack: {
                        closeFavouriteList()
                    },
                    onSelect: { recipe in
                        closeFavouriteList(opening: recipe)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .trailing))
                .zIndex(50)
            }
        }
    }

    private var todayRecipesSection: some View {
        let recipes = appVM.todayMenuRecipes

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Today’s Recipes", showsMoreButton: false)

            if recipes.isEmpty {
                emptyMenuCard(
                    title: "No recipe generated today",
                    message: "Generate from DishRoller to add a recipe here."
                )
            } else {
                todayRecipeCarousel(recipes)
            }
        }
        .onChange(of: recipes.count) { _, newCount in
            selectedTodayRecipeIndex = min(selectedTodayRecipeIndex, max(newCount - 1, 0))
        }
    }

    private func todayRecipeCarousel(_ recipes: [Recipe]) -> some View {
        let visibleIndices = Array(
            selectedTodayRecipeIndex..<min(selectedTodayRecipeIndex + 3, recipes.count)
        )

        return VStack(spacing: 10) {
            ZStack {
                ForEach(visibleIndices.reversed(), id: \.self) { index in
                    let depth = index - selectedTodayRecipeIndex
                    let sideOffset: CGFloat = depth == 1 ? 16 : (depth == 2 ? -16 : 0)

                    todayRecipeCard(recipes[index])
                        .offset(
                            x: sideOffset + (depth == 0 ? todayCarouselDrag : 0),
                            y: 0
                        )
                        .opacity(1 - (Double(depth) * 0.16))
                        .zIndex(Double(3 - depth))
                        .allowsHitTesting(depth == 0)
                }
            }
            .frame(height: 178)
            .padding(.horizontal, recipes.count > 1 ? 18 : 0)
            .contentShape(Rectangle())
            .gesture(todayCarouselGesture(recipeCount: recipes.count))

            if recipes.count > 1 {
                HStack(spacing: 6) {
                    ForEach(recipes.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedTodayRecipeIndex ? Color.black : Color.black.opacity(0.16))
                            .frame(width: index == selectedTodayRecipeIndex ? 18 : 6, height: 6)
                    }
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.82), value: selectedTodayRecipeIndex)
            }
        }
    }

    private func todayRecipeCard(_ recipe: Recipe) -> some View {
        let isFavourite = appVM.savedRecipesVM.isSaved(recipe)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.28))
                        .frame(width: 52, height: 52)

                    Image(systemName: "fork.knife")
                        .font(.title3.weight(.black))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(recipe.title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(recipe.estimatedTime)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.gray)
                }

                Spacer(minLength: 8)

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                        appVM.toggleSavedState(for: recipe)
                    }
                } label: {
                    Image(systemName: isFavourite ? "star.fill" : "star")
                        .font(.caption.weight(.black))
                        .foregroundColor(isFavourite ? .yellow : .black)
                        .frame(width: 32, height: 32)
                        .background(isFavourite ? Color.black : Color.yellow)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavourite ? "Remove from favourites" : "Add to favourites")
            }

            HStack(spacing: 6) {
                ForEach(Array(recipe.flavourTags.prefix(3)), id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.black))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Color.yellow.opacity(0.42))
                        .clipShape(Capsule())
                }
            }

            HStack {
                Label("\(recipe.ingredients.count) ingredients", systemImage: "basket")
                    .font(.caption.weight(.black))
                    .foregroundColor(.black.opacity(0.66))

                Spacer()

                Button {
                    appVM.presentRecipe(recipe)
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.black))
                        .foregroundColor(.yellow)
                        .frame(width: 32, height: 32)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(recipe.title)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 174, maxHeight: 174, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 2)
    }

    private func todayCarouselGesture(recipeCount: Int) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($todayCarouselDrag) { value, state, _ in
                state = max(-90, min(24, value.translation.width))
            }
            .onEnded { value in
                let shouldAdvance = value.translation.width < -45 || value.predictedEndTranslation.width < -90
                let shouldGoBack = value.translation.width > 45 || value.predictedEndTranslation.width > 90

                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    if shouldAdvance, selectedTodayRecipeIndex < recipeCount - 1 {
                        selectedTodayRecipeIndex += 1
                    } else if shouldGoBack, selectedTodayRecipeIndex > 0 {
                        selectedTodayRecipeIndex -= 1
                    }
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
                withAnimation(.easeInOut(duration: 0.32)) {
                    appVM.isRecipeHistoryPresented = true
                }
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)
                    .frame(width: 72, height: 48)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Recipe history")
        }
    }

    private func menuSection(
        title: String,
        recipes: [Recipe],
        emptyTitle: String,
        emptyMessage: String,
        showsSavedIndicator: Bool,
        showsCookCount: Bool,
        showsMoreButton: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title, showsMoreButton: showsMoreButton)

            if recipes.isEmpty {
                emptyMenuCard(title: emptyTitle, message: emptyMessage)
            } else {
                VStack(spacing: 10) {
                    ForEach(recipes) { recipe in
                        menuSummaryCard(
                            recipe,
                            showsSavedIndicator: showsSavedIndicator,
                            showsCookCount: showsCookCount
                        )
                    }
                }
                .padding(.horizontal, title == "Favourite" ? 2 : 0)
            }
        }
    }

    private func sectionTitle(_ title: String, showsMoreButton: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            if showsMoreButton {
                Button {
                    withAnimation(.easeInOut(duration: 0.32)) {
                        appVM.isFavouriteListPresented = true
                    }
                } label: {
                    Text("Show more")
                        .font(.subheadline.weight(.black))
                        .underline()
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show all favourite recipes")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 2)
    }

    private func menuSummaryCard(
        _ recipe: Recipe,
        showsSavedIndicator: Bool,
        showsCookCount: Bool
    ) -> some View {
        Button {
            appVM.presentRecipe(recipe)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Text(recipe.title)
                        .font(.headline.weight(.black))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    if showsCookCount {
                        Text(cookCountText(for: recipe))
                            .font(.caption.weight(.black))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .padding(.horizontal, 9)
                            .frame(height: 26)
                            .background(Color.yellow.opacity(0.52))
                            .clipShape(Capsule())
                    }
                }

                Text(recipe.estimatedTime)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.gray)

                HStack(alignment: .center, spacing: 8) {
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

                    Spacer(minLength: 8)

                    Image(systemName: summaryIconName(for: recipe, showsSavedIndicator: showsSavedIndicator))
                        .font(.headline.weight(.black))
                        .foregroundColor(.black)
                        .frame(width: 34, height: 34)
                        .background(showsSavedIndicator ? Color.clear : Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 138, maxHeight: 138, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func summaryIconName(for recipe: Recipe, showsSavedIndicator: Bool) -> String {
        guard showsSavedIndicator else { return "chevron.right" }
        return recipe.isSaved ? "star.fill" : "star"
    }

    private func cookCountText(for recipe: Recipe) -> String {
        let count = appVM.cookCount(for: recipe)
        return count == 1 ? "1 time" : "\(count) times"
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

    private func recipeFullPage(recipe: Recipe) -> some View {
        ZStack {
            Color.yellow
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        appVM.dismissCurrentRecipe()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.black))
                            .foregroundColor(.yellow)
                            .frame(width: 48, height: 48)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back to recipes")

                    Spacer()

                    Text("Recipe Details")
                        .font(.headline.weight(.black))
                        .foregroundColor(.black)

                    Spacer()

                    Color.clear
                        .frame(width: 48, height: 48)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.yellow)

                ScrollView {
                    RecipeCardView(
                        recipe: recipe,
                        menuVM: vm,
                        storageIngredients: appVM.storageVM.ingredients,
                        showsGeneratedActions: appVM.currentRecipeContext != nil,
                        onLeave: {
                            appVM.dismissCurrentRecipe()
                        }
                    )
                    .environmentObject(appVM)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
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

    private func closeHistory(opening recipe: Recipe? = nil) {
        withAnimation(.easeInOut(duration: 0.32)) {
            appVM.isRecipeHistoryPresented = false
        }

        guard let recipe else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            appVM.presentRecipe(recipe)
        }
    }

    private func closeFavouriteList(opening recipe: Recipe? = nil) {
        withAnimation(.easeInOut(duration: 0.32)) {
            appVM.isFavouriteListPresented = false
        }

        guard let recipe else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            appVM.presentRecipe(recipe)
        }
    }
}

private struct RecipeHistoryView: View {
    let records: [DailyGeneratedRecipe]
    let onBack: () -> Void
    let onClear: () -> Void
    let onSelect: (Recipe) -> Void

    @State private var confirmClear = false

    private var groupedRecords: [(date: Date, records: [DailyGeneratedRecipe])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: records) {
            calendar.startOfDay(for: $0.generatedAt)
        }

        return groups
            .map { (date: $0.key, records: $0.value.sorted { $0.generatedAt > $1.generatedAt }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if records.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(groupedRecords, id: \.date) { group in
                            historySection(group)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(historyPageBackground)
        .ignoresSafeArea(edges: .bottom)
        .alert("Clear Recipe History?", isPresented: $confirmClear) {
            Button("Clear", role: .destructive) {
                onClear()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all generated recipe records. Saved recipes will not be deleted.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.yellow)
                    .frame(width: 46, height: 46)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to recipes")

            Text("Recipe History")
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(.black)

            Spacer()

            Button {
                confirmClear = true
            } label: {
                Text("Clear")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(records.isEmpty ? Color.gray : Color.yellow)
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .background(records.isEmpty ? Color(.systemGray5) : Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(records.isEmpty)
            .accessibilityLabel("Clear recipe history")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(red: 1, green: 0.82, blue: 0.05))
    }

    private var historyPageBackground: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 1, green: 0.82, blue: 0.05)

                Image("shopping-food-pattern")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.24)

                Color.yellow.opacity(0.12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(.black)

            Text("No Recipe History")
                .font(.title3.weight(.black))

            Text("Recipes generated with DishRoller will appear here by date.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func historySection(
        _ group: (date: Date, records: [DailyGeneratedRecipe])
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dateTitle(group.date))
                .font(.title3.weight(.black))
                .foregroundStyle(.black)

            VStack(spacing: 10) {
                ForEach(group.records) { record in
                    Button {
                        onSelect(record.recipe)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(record.recipe.title)
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(.black)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                HStack(spacing: 8) {
                                    Text(record.generatedAt.formatted(date: .omitted, time: .shortened))
                                    Text("•")
                                    Text(record.recipe.estimatedTime)
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.gray)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(.black)
                                .frame(width: 34, height: 34)
                                .background(Color.yellow)
                                .clipShape(Circle())
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dateTitle(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(date: .long, time: .omitted)
    }
}

private struct FavouriteRecipesView: View {
    let recipes: [Recipe]
    let cookCount: (Recipe) -> Int
    let onBack: () -> Void
    let onSelect: (Recipe) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            if recipes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(recipes) { recipe in
                            favouriteCard(recipe)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(favouritePageBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        ZStack {
            Text("Favourite")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.black)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.yellow)
                        .frame(width: 46, height: 46)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to recipes")

                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(red: 1, green: 0.82, blue: 0.05))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.slash")
                .font(.system(size: 42, weight: .black))

            Text("No Favourite Recipes")
                .font(.title3.weight(.black))

            Text("Recipes saved with the star button will appear here.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func favouriteCard(_ recipe: Recipe) -> some View {
        Button {
            onSelect(recipe)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Text(recipe.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Text(cookCountText(for: recipe))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .frame(height: 26)
                        .background(Color.yellow.opacity(0.52))
                        .clipShape(Capsule())
                }

                Text(recipe.estimatedTime)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)

                HStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 6) {
                        ForEach(Array(recipe.flavourTags.prefix(3)), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.42))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.black)
                        .frame(width: 34, height: 34)
                        .background(Color.yellow)
                        .clipShape(Circle())
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 138, maxHeight: 138, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func cookCountText(for recipe: Recipe) -> String {
        let count = cookCount(recipe)
        return count == 1 ? "1 time" : "\(count) times"
    }

    private var favouritePageBackground: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 1, green: 0.82, blue: 0.05)

                Image("shopping-food-pattern")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.24)

                Color.yellow.opacity(0.12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct RecipeCardView: View {
    @EnvironmentObject private var appVM: AppViewModel

    let recipe: Recipe
    let menuVM: MenuViewModel
    let storageIngredients: [Ingredient]
    let showsGeneratedActions: Bool
    let onLeave: () -> Void

    @State private var recipeRating = 0
    @State private var sharePayload: RecipeSharePayload?

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
        .fullScreenCover(
            item: $sharePayload,
            onDismiss: {
                sharePayload = nil
            }
        ) { payload in
            RecipeSharePreviewScreen(
                payload: payload,
                onClose: {
                    sharePayload = nil
                }
            )
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if showsGeneratedActions {
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

            Button {
                shareRecipe()
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline.weight(.black))

                    Text("Share Recipe")
                        .font(.headline.weight(.black))
                }
                .foregroundColor(.yellow)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.black)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share recipe as an image")
        }
        .padding(.top, 4)
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

    @MainActor
    private func shareRecipe() {
        let renderer = ImageRenderer(
            content: RecipeShareImage(recipe: recipe)
                .frame(width: 390)
        )
        renderer.proposedSize = ProposedViewSize(width: 390, height: nil)
        renderer.scale = 2
        renderer.isOpaque = true

        guard let image = renderer.uiImage else { return }
        sharePayload = RecipeSharePayload(image: image)
    }
}

private struct RecipeSharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct RecipeActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

private struct RecipeSharePreviewScreen: View {
    let payload: RecipeSharePayload
    let onClose: () -> Void

    @State private var showSystemShare = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.58)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }

            GeometryReader { proxy in
                Image(uiImage: payload.image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: proxy.size.width - 58,
                        maxHeight: proxy.size.height * 0.60
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.34), radius: 20, y: 10)
                    .position(
                        x: proxy.size.width / 2,
                        y: max((proxy.size.height * 0.32), 190)
                    )
            }
            .allowsHitTesting(false)

            shareSelectionCard
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
        }
        .sheet(isPresented: $showSystemShare) {
            RecipeActivityView(items: [payload.image])
                .presentationDetents([.medium, .large])
        }
    }

    private var shareSelectionCard: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.black.opacity(0.16))
                .frame(width: 42, height: 5)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Share Recipe")
                        .font(.title2.weight(.black))
                        .foregroundStyle(.black)

                    Text("Your complete recipe screenshot is ready.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.gray)
                }

                Spacer(minLength: 12)

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.black)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close share preview")
            }

            HStack(spacing: 0) {
                shareDestination(
                    title: "Instagram",
                    mark: "◎",
                    background: AnyShapeStyle(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )

                shareDestination(
                    title: "Facebook",
                    mark: "f",
                    background: AnyShapeStyle(Color(red: 0.10, green: 0.42, blue: 0.88))
                )

                shareDestination(
                    title: "X",
                    mark: "𝕏",
                    background: AnyShapeStyle(Color.black)
                )

                shareDestination(
                    title: "More",
                    mark: "•••",
                    background: AnyShapeStyle(Color(.systemGray3))
                )
            }

            Text("Installed sharing apps will appear in the iOS share window.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 24, y: 12)
    }

    private func shareDestination(
        title: String,
        mark: String,
        background: AnyShapeStyle
    ) -> some View {
        Button {
            showSystemShare = true
        } label: {
            VStack(spacing: 7) {
                Text(mark)
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(background)
                    .clipShape(Circle())

                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share using \(title)")
    }
}

private struct RecipeShareImage: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 34, weight: .black))

                Text("DishRoller")
                    .font(.title2.weight(.black))
            }

            Text(recipe.title)
                .font(.system(size: 32, weight: .black))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text("Estimated Time:")
                    .fontWeight(.black)
                Text(recipe.estimatedTime)
            }
            .font(.headline)

            if !recipe.flavourTags.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Flavour")
                        .font(.title3.weight(.black))

                    FlavourTagFlowView(tags: recipe.flavourTags)
                }
            }

            shareSection(title: "Ingredients") {
                VStack(spacing: 0) {
                    ForEach(recipe.ingredients) { ingredient in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(ingredient.name)
                                .font(.headline.weight(.black))

                            Spacer(minLength: 12)

                            Text(shareAmount(for: ingredient))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.black.opacity(0.68))
                        }
                        .padding(.vertical, 11)

                        if ingredient.id != recipe.ingredients.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            shareSection(title: "Procedure") {
                VStack(spacing: 12) {
                    ForEach(Array(recipe.procedure.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text(step.emoji)
                                .font(.title2)
                                .frame(width: 42, height: 42)
                                .background(Color.yellow.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Step \(index + 1)")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.gray)

                                Text(step.instruction)
                                    .font(.body.weight(.semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }

            Text("Spin it. Cook it. Love it.")
                .font(.subheadline.weight(.black))
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .foregroundStyle(.black)
        .padding(22)
        .background(Color.yellow)
    }

    private func shareAmount(for ingredient: RecipeIngredient) -> String {
        guard let form = ingredient.form, !form.isEmpty else {
            return ingredient.amount
        }
        return "\(ingredient.amount) · \(form)"
    }

    private func shareSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.black))
            content()
        }
    }
}

#Preview {
    let appVM = AppViewModel.previewSample

    MenuView()
        .environmentObject(appVM)
}
