//
//  DishRollerView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI
import Combine

struct DishRollerView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case raw = "Raw"
        case dishes = "Dishes"

        var id: String { rawValue }
    }

    private enum ControlPanelTab {
        case selection
        case results
    }

    private struct WeightedWheelSegment: Identifiable {
        let ingredient: Ingredient
        let startAngle: Double
        let endAngle: Double

        var id: UUID { ingredient.id }
        var midAngle: Double { startAngle + ((endAngle - startAngle) / 2) }
    }

    private struct RecipeWheelSegment: Identifiable {
        let recipe: Recipe
        let startAngle: Double
        let endAngle: Double

        var id: UUID { recipe.id }
        var midAngle: Double { startAngle + ((endAngle - startAngle) / 2) }
    }

    private let comboCategories: [IngredientCategory] = [.meat, .seafood, .veg]

    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = DishRollerViewModel()
    @State private var selectedMode: Mode = .raw
    @State private var isSpinning = false
    @State private var wheelRotation = 0.0
    @State private var spinTimer: Timer?
    @State private var wheelIngredientSnapshot: [Ingredient] = []
    @State private var wheelRecipeSnapshot: [Recipe] = []
    @State private var wheelExpiryModeSnapshot: Bool?
    @State private var selectedDishRecipe: Recipe?
    @State private var remainingSpins = 3
    @State private var selectedComboCategories: Set<IngredientCategory> = [.meat, .seafood, .veg]
    @State private var isExpiredFirstEnabled = false
    @State private var magicPulse = false
    @State private var magicRotation = 0.0
    @State private var showPreferenceBasket = false
    @State private var activeControlPanel: ControlPanelTab = .selection
    @State private var controlPanelPage = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    controlPanelCarousel
                    modeBar
                    wheelView
                        .padding(.top, -30)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(pageBackground)
            .navigationBarHidden(true)
        }
        .overlay(alignment: .top) {
            if vm.isLoading {
                generatingMagicCard
                    .padding(.top, 88)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: vm.isLoading)
        .alert("Notice", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { _ in vm.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .sheet(isPresented: $showPreferenceBasket) {
            PreferenceBasketSheet(
                vm: vm,
                storageIngredients: appVM.storageVM.ingredients
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: vm.isLoading) { _, isLoading in
            updateMagicAnimation(isLoading: isLoading)
        }
        .onChange(of: nearExpiryIngredients.map(\.id)) { oldIDs, newIDs in
            if oldIDs.isEmpty, !newIDs.isEmpty {
                controlPanelPage = 0
            } else if newIDs.isEmpty {
                controlPanelPage = 0
            }
        }
        .onDisappear {
            stopSpinTimer()
            updateMagicAnimation(isLoading: false)
        }
    }

    private var header: some View {
        HStack {
            Text("DishRoller")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            NavigationLink {
                AvoidancePreferencesView()
                    .environmentObject(appVM)
            } label: {
                ZStack(alignment: .trailing) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 23, height: 23)
                        .frame(width: 72, height: 48)

                    if selectedAvoidanceCardCount > 0 {
                        HStack {
                            Text(selectedAvoidanceCountText)
                                .font(.caption.weight(.black))
                                .foregroundStyle(.yellow)
                                .frame(width: 28, height: 28)
                                .background(Color.black)
                                .clipShape(Circle())
                                .transition(.scale.combined(with: .opacity))

                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 10)
                    }
                }
                .frame(width: selectedAvoidanceCardCount > 0 ? 100 : 72, height: 48)
                .background(Color.yellow)
                .clipShape(Capsule())
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.82),
                    value: selectedAvoidanceCardCount
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Avoid Foods")
            .accessibilityValue("\(selectedAvoidanceCardCount) active cards")
        }
    }

    private var selectedAvoidanceCardCount: Int {
        appVM.avoidanceVM.selectedProfileCount
    }

    private var selectedAvoidanceCountText: String {
        selectedAvoidanceCardCount > 99 ? "99+" : "\(selectedAvoidanceCardCount)"
    }

    private var pageBackground: Color {
        Color(red: 0.96, green: 0.95, blue: 0.98)
    }

    @ViewBuilder
    private var controlPanelCarousel: some View {
        if nearExpiryIngredients.isEmpty {
            controlPanel
        } else {
            VStack(spacing: 10) {
                TabView(selection: $controlPanelPage) {
                    expiryNotificationPanel
                        .tag(0)

                    controlPanel
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: controlPanelHeight)

                HStack(spacing: 6) {
                    Capsule()
                        .fill(controlPanelPage == 0 ? Color.black : Color.black.opacity(0.22))
                        .frame(width: controlPanelPage == 0 ? 18 : 6, height: 6)

                    Capsule()
                        .fill(controlPanelPage == 1 ? Color.black : Color.black.opacity(0.22))
                        .frame(width: controlPanelPage == 1 ? 18 : 6, height: 6)
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.82), value: controlPanelPage)
            }
        }
    }

    private var expiryNotificationPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack {
                Text("Cook These Soon")
                    .font(.system(size: 21, weight: .black))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 21, weight: .black))
                        .foregroundStyle(.yellow)
                        .frame(width: 44, height: 44)
                        .background(Color.black)
                        .clipShape(Circle())

                    Spacer()
                }
            }

            Text(expiryNotificationSummary)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(nearExpiryIngredients.map(\.name).joined(separator: " • "))
                .font(.system(size: nearExpiryIngredients.count >= 4 ? 12 : 14, weight: .black))
                .foregroundStyle(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)

            Spacer(minLength: 14)

            Button(action: cookNearExpiryIngredients) {
                Text("Cook Them")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.yellow)
                    .frame(width: 220)
                    .frame(height: 42)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, minHeight: controlPanelHeight, alignment: .topLeading)
        .background(panelYellowGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
    }

    private var controlPanel: some View {
        let isSelectionActive = activeControlPanel == .selection

        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black)
                .frame(height: controlPanelHeight)

            ControlFolderShape(tabOnLeft: !isSelectionActive)
                .fill(Color.black)
                .frame(height: controlPanelHeight)

            ControlFolderShape(tabOnLeft: isSelectionActive)
                .fill(panelYellowGradient)
                .frame(height: controlPanelHeight)

            controlPanelTabs

            Group {
                switch activeControlPanel {
                case .selection:
                    selectionPanelContent
                case .results:
                    resultsPanelContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 72)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: controlPanelHeight)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: activeControlPanel)
    }

    private var panelYellowGradient: LinearGradient {
        LinearGradient(
            colors: [Color.yellow, Color(red: 1, green: 0.88, blue: 0.32)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var controlPanelHeight: CGFloat {
        224
    }

    private var controlPanelTabs: some View {
        HStack(spacing: 0) {
            controlPanelTabButton(.selection, title: "Selection")
                .frame(maxWidth: .infinity)

            controlPanelTabButton(.results, title: "Results")
                .frame(maxWidth: .infinity)
        }
        .frame(height: 60)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private func controlPanelTabButton(_ tab: ControlPanelTab, title: String) -> some View {
        Button {
            activeControlPanel = tab
        } label: {
            Text(title)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(activeControlPanel == tab ? .black : .yellow)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show \(title)")
    }

    @ViewBuilder
    private var selectionPanelContent: some View {
        if selectedMode == .dishes {
            VStack(alignment: .leading, spacing: 10) {
                Text("Saved Recipe Spin")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.black)

                Text("The wheel uses recipes from your saved collection.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.68))

                Text("\(appVM.savedRecipesVM.savedRecipes.count) recipes available")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            rawSelectionPanelContent
        }
    }

    private var rawSelectionPanelContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                LocalSelectionMenu(
                    title: "Time",
                    initialSelection: vm.selectedTime,
                    options: CookingTime.allCases,
                    label: \.rawValue,
                    onSelection: { vm.selectedTime = $0 }
                )

                LocalSelectionMenu(
                    title: "Type",
                    initialSelection: vm.selectedType,
                    options: DishType.allCases,
                    label: \.rawValue,
                    onSelection: { vm.selectedType = $0 }
                )
            }

            HStack(spacing: 12) {
                LocalSelectionMenu(
                    title: "Flavour",
                    initialSelection: vm.selectedStyle,
                    options: FlavourStyle.allCases,
                    label: \.rawValue,
                    onSelection: { vm.selectedStyle = $0 }
                )

                HStack(spacing: 8) {
                    Text("Preference")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer(minLength: 0)

                    preferenceBasketIcon
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                comboMoreMenu
                expiredFirstButton
            }
        }
    }

    @ViewBuilder
    private var resultsPanelContent: some View {
        if selectedMode == .dishes {
            dishResultsPanelContent
        } else {
            rawResultsPanelContent
        }
    }

    private var rawResultsPanelContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlowResultView(results: vm.selectedResults) { ingredient in
                removeSelectedResult(ingredient)
            }
            .frame(minHeight: 58, alignment: .leading)

            Spacer(minLength: 8)

            HStack(spacing: 14) {
                generateButton
                clearButton
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var nearExpiryIngredients: [Ingredient] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var seenNames: Set<String> = []

        return appVM.storageVM.ingredients
            .filter { ingredient in
                guard ingredient.amount > 0, let expiryDate = ingredient.expiryDate else {
                    return false
                }
                let expiryDay = calendar.startOfDay(for: expiryDate)
                let days = calendar.dateComponents([.day], from: today, to: expiryDay).day ?? 2
                return (0...1).contains(days)
            }
            .sorted {
                ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture)
            }
            .filter { ingredient in
                let key = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !seenNames.contains(key) else { return false }
                seenNames.insert(key)
                return true
            }
    }

    private var expiryNotificationSummary: String {
        let count = nearExpiryIngredients.count
        return count == 1
            ? "1 storage item expires today or tomorrow."
            : "\(count) storage items expire today or tomorrow."
    }

    private func cookNearExpiryIngredients() {
        selectedMode = .raw
        vm.clearResults()

        for ingredient in nearExpiryIngredients.prefix(5) {
            vm.addSelection(ingredient)
        }

        activeControlPanel = .results
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            controlPanelPage = 1
        }
    }

    private var dishResultsPanelContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedDishRecipe {
                VStack(alignment: .leading, spacing: 5) {
                    Text(selectedDishRecipe.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.black)
                        .lineLimit(2)

                    Text(selectedDishRecipe.estimatedTime)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 14) {
                    Button("Open Recipe") {
                        appVM.presentRecipe(selectedDishRecipe)
                    }
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.yellow)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.black)
                    .clipShape(Capsule())

                    clearButton
                }
                .buttonStyle(.plain)
            } else {
                Text("Spin the wheel to choose a saved recipe.")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black.opacity(0.65))
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            }
        }
    }

    private struct ControlFolderShape: Shape {
        let tabOnLeft: Bool

        func path(in rect: CGRect) -> Path {
            let width = rect.width
            let height = rect.height
            let corner: CGFloat = 24
            let step: CGFloat = 58
            let curveStart = width * 0.47
            let curveEnd = width * 0.61

            var path = Path()

            if tabOnLeft {
                path.move(to: CGPoint(x: corner, y: 0))
                path.addLine(to: CGPoint(x: curveStart, y: 0))
                path.addCurve(
                    to: CGPoint(x: curveEnd, y: step),
                    control1: CGPoint(x: width * 0.50, y: 0),
                    control2: CGPoint(x: width * 0.49, y: step)
                )
                path.addLine(to: CGPoint(x: width - corner, y: step))
                path.addQuadCurve(
                    to: CGPoint(x: width, y: step + corner),
                    control: CGPoint(x: width, y: step)
                )
                path.addLine(to: CGPoint(x: width, y: height - corner))
                path.addQuadCurve(
                    to: CGPoint(x: width - corner, y: height),
                    control: CGPoint(x: width, y: height)
                )
                path.addLine(to: CGPoint(x: corner, y: height))
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: height - corner),
                    control: CGPoint(x: 0, y: height)
                )
                path.addLine(to: CGPoint(x: 0, y: corner))
                path.addQuadCurve(
                    to: CGPoint(x: corner, y: 0),
                    control: CGPoint(x: 0, y: 0)
                )
            } else {
                path.move(to: CGPoint(x: corner, y: step))
                path.addLine(to: CGPoint(x: width - curveEnd, y: step))
                path.addCurve(
                    to: CGPoint(x: width - curveStart, y: 0),
                    control1: CGPoint(x: width - width * 0.49, y: step),
                    control2: CGPoint(x: width - width * 0.50, y: 0)
                )
                path.addLine(to: CGPoint(x: width - corner, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: width, y: corner),
                    control: CGPoint(x: width, y: 0)
                )
                path.addLine(to: CGPoint(x: width, y: height - corner))
                path.addQuadCurve(
                    to: CGPoint(x: width - corner, y: height),
                    control: CGPoint(x: width, y: height)
                )
                path.addLine(to: CGPoint(x: corner, y: height))
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: height - corner),
                    control: CGPoint(x: 0, y: height)
                )
                path.addLine(to: CGPoint(x: 0, y: step + corner))
                path.addQuadCurve(
                    to: CGPoint(x: corner, y: step),
                    control: CGPoint(x: 0, y: step)
                )
            }

            path.closeSubpath()
            return path
        }
    }

    private var generatingMagicCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Text("✨")
                    .font(.system(size: 26))
                    .offset(x: -18, y: -12)
                    .scaleEffect(magicPulse ? 1.2 : 0.7)
                    .opacity(magicPulse ? 1 : 0.45)

                Text("🪄")
                    .font(.system(size: 34))
                    .rotationEffect(.degrees(magicRotation))
                    .scaleEffect(magicPulse ? 1.05 : 0.95)

                Text("✨")
                    .font(.system(size: 20))
                    .offset(x: 20, y: 14)
                    .scaleEffect(magicPulse ? 0.75 : 1.25)
                    .opacity(magicPulse ? 0.5 : 1)
            }
            .frame(width: 58, height: 58)
            .background(Color.yellow.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Generating magic...")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)

                Text("Cooking up a cute recipe")
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

    private var preferenceBasketIcon: some View {
        Button {
            showPreferenceBasket = true
        } label: {
            Group {
                if vm.selectedResults.isEmpty {
                    Image(systemName: "basket")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    Text("\(vm.selectedResults.count)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.yellow)
                }
            }
                .frame(width: 40, height: 40)
                .background(vm.selectedResults.isEmpty ? Color.yellow : Color.black)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
                .animation(
                    .spring(response: 0.28, dampingFraction: 0.8),
                    value: vm.selectedResults.count
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open preference basket")
        .accessibilityValue("\(vm.selectedResults.count) ingredients selected")
    }

    private var comboMoreMenu: some View {
        Menu {
            ForEach(comboCategories) { category in
                Button {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        toggleComboCategory(category)
                    }
                } label: {
                    HStack {
                        Text(category.menuTitle)
                        Spacer()
                        if selectedComboCategories.contains(category) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("Combo")
                    .font(.subheadline.weight(.black))
                    .underline()

                Text(comboSelectionTitle)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.black))
            }
            .foregroundColor(.black.opacity(0.72))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expiredFirstButton: some View {
        Button {
            guard !isSpinning else { return }
            isExpiredFirstEnabled.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isExpiredFirstEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.black))

                Text("Expired First")
                    .font(.caption.weight(.black))
                    .lineLimit(1)
            }
            .foregroundStyle(isExpiredFirstEnabled ? Color.yellow : Color.black)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(isExpiredFirstEnabled ? Color.black : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(isExpiredFirstEnabled ? 0 : 0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSpinning)
        .accessibilityLabel("Expired First")
        .accessibilityValue(isExpiredFirstEnabled ? "On" : "Off")
    }

    @ViewBuilder
    private func compactSelectionGroup<Content: View, Title: View>(
        title: String,
        @ViewBuilder titleView: () -> Title,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            menuCapsule(titleView: titleView, content: content)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var generateButton: some View {
        Button {
            Task {
                let context = RecipeGenerationContext(
                    ingredients: vm.selectedResults,
                    time: vm.selectedTime,
                    type: vm.selectedType,
                    style: vm.selectedStyle,
                    customPreferences: ""
                )
                if let recipe = await vm.generateRecipe(
                    avoidancePrompt: appVM.avoidanceVM.selectedAvoidancePrompt
                ) {
                    appVM.openMenu(with: recipe, context: context)
                    resetRound()
                }
            }
        } label: {
            Text(vm.isLoading ? "Loading..." : "Generate")
                .font(.subheadline.weight(.black))
                .foregroundColor(.yellow)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.black)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(vm.selectedResults.isEmpty || vm.isLoading)
    }

    private var clearButton: some View {
        Button {
            resetRound()
        } label: {
            Text("Clear")
                .font(.subheadline.weight(.black))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var comboSelectionGroup: some View {
        HStack(spacing: 10) {
            Text("Combo")
                .font(.headline)
                .fontWeight(.black)
                .foregroundColor(.yellow)
                .frame(minWidth: 60, alignment: .leading)

            Menu {
                ForEach(comboCategories) { category in
                    Button {
                        toggleComboCategory(category)
                    } label: {
                        HStack {
                            Text(category.menuTitle)
                            Spacer()
                            if selectedComboCategories.contains(category) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(comboSelectionTitle)
                        .font(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.white)
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func selectionGroup<Content: View, Title: View>(
        title: String,
        titleMinWidth: CGFloat,
        @ViewBuilder titleView: () -> Title,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.black)
                .foregroundColor(.yellow)
                .frame(minWidth: titleMinWidth, alignment: .leading)

            menuCapsule(
                titleView: titleView,
                content: content
            )
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func menuCapsule<Content: View, Title: View>(
        @ViewBuilder titleView: () -> Title,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 6) {
                titleView()
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Color.white)
            .clipShape(Capsule())
        }
    }
    

    private var modeBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Modes:")
                        .font(.system(size: 22, weight: .black))
                        .fontWeight(.black)

                    Text("Chances left: \(remainingSpins)/3")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack(spacing: 4) {
                    ForEach(Mode.allCases) { mode in
                        Button {
                            switchMode(to: mode)
                        } label: {
                            Text(mode.rawValue)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(selectedMode == mode ? .black : .yellow)
                                .lineLimit(1)
                                .frame(minWidth: 64)
                                .frame(height: 32)
                                .background(selectedMode == mode ? Color.yellow : Color.clear)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color.black)
                .clipShape(Capsule())
            }
        }
    }

    private var availableWheelIngredients: [Ingredient] {
        vm.selectableIngredients(
            from: appVM.storageVM.ingredients,
            matching: eligibleWheelCategories
        )
    }

    private var eligibleWheelCategories: Set<IngredientCategory> {
        var categories = selectedComboCategories
        guard selectedComboCategories.count > 1 else {
            return categories
        }

        let selectedCategories = Set(vm.selectedResults.map(\.category))

        if selectedCategories.contains(.meat) {
            categories.remove(.meat)
        }

        if selectedCategories.contains(.seafood) {
            categories.remove(.seafood)
        }

        return categories
    }

    private var wheelIngredients: [Ingredient] {
        wheelIngredientSnapshot.isEmpty ? availableWheelIngredients : wheelIngredientSnapshot
    }

    private var wheelRecipes: [Recipe] {
        wheelRecipeSnapshot.isEmpty ? appVM.savedRecipesVM.savedRecipes : wheelRecipeSnapshot
    }

    private var wheelUsesExpiryWeighting: Bool {
        wheelExpiryModeSnapshot ?? isExpiredFirstEnabled
    }

    private var comboSelectionTitle: String {
        let orderedSelections = comboCategories.filter { selectedComboCategories.contains($0) }
        guard !orderedSelections.isEmpty else { return "Select tags" }
        return orderedSelections.map(\.menuTitle).joined(separator: ", ")
    }

    private func wheelSelection(from ingredients: [Ingredient]) -> Ingredient? {
        guard !ingredients.isEmpty else { return nil }
        guard ingredients.count > 1 else { return ingredients[0] }

        let segments = wheelSegments(for: ingredients, expiryFirst: wheelUsesExpiryWeighting)
        let localPointerAngle = normalizedDegrees(-90 - wheelRotation)

        return segments.first { segment in
            angle(localPointerAngle, isWithinStart: segment.startAngle, end: segment.endAngle)
        }?.ingredient ?? segments.last?.ingredient
    }

    private var wheelView: some View {
        Group {
            if selectedMode == .dishes {
                dishWheelView
            } else {
                rawWheelView
            }
        }
    }

    private var rawWheelView: some View {
        VStack(spacing: 8) {
            if wheelIngredients.isEmpty {
                Text("Add ingredients in Storage to use the turntable.")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                GeometryReader { geometry in
                    let wheelSize = geometry.size.width * 1.4

                    ZStack {
                        Ellipse()
                            .fill(Color.black.opacity(0.16))
                            .frame(width: wheelSize * 0.72, height: 38)
                            .blur(radius: 14)
                            .offset(y: 284)

                        turntableWheel
                            .frame(width: wheelSize, height: wheelSize)
                            .padding(16)
                            .drawingGroup(opaque: false, colorMode: .nonLinear)
                            .rotationEffect(.degrees(wheelRotation))
                            .padding(-16)
                            .offset(x: 0, y: 122)
                            .frame(width: 370, height: 304)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .shadow(color: .black.opacity(0.2), radius: 18, y: 10)

                        VStack(spacing: 0) {
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.black, Color.black.opacity(0.78)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 20, height: 106)
                                .overlay(
                                    Triangle()
                                        .stroke(Color.yellow, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 10, y: 3)

                            Button {
                                toggleWheelSpin()
                            } label: {
                                Text(isSpinning ? "Stop" : "Start")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(isSpinning ? .yellow : .black)
                                    .frame(width: 102, height: 102)
                                    .background(
                                        RadialGradient(
                                            colors: isSpinning
                                            ? [Color.black.opacity(0.82), .black]
                                            : [Color.yellow.opacity(0.92), .yellow],
                                            center: .topLeading,
                                            startRadius: 12,
                                            endRadius: 82
                                        )
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 5)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.55), lineWidth: 2)
                                            .padding(8)
                                    )
                                    .scaleEffect(isSpinning ? 1.05 : 1)
                                    .shadow(color: .black.opacity(0.24), radius: 14, y: 7)
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(response: 0.24, dampingFraction: 0.7), value: isSpinning)
                            .offset(y: -10)
                        }
                        .offset(x: 0, y: 48)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .clipped()
                }
                .frame(height: 340)
            }
        }
    }

    private var dishWheelView: some View {
        VStack(spacing: 8) {
            if wheelRecipes.isEmpty {
                ZStack {
                    fadedEmptyRecipeWheel
                        .opacity(0.24)

                    VStack(spacing: 8) {
                        Image(systemName: "bookmark.slash.fill")
                            .font(.title2.weight(.black))

                        Text("You haven't saved any recipe yet")
                            .font(.headline.weight(.black))
                            .multilineTextAlignment(.center)

                        Text("Try to generate one first.")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.gray)
                    }
                    .foregroundStyle(.black)
                    .padding(18)
                    .frame(maxWidth: 320)
                    .background(Color.white.opacity(0.94))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .clipped()
            } else {
                GeometryReader { geometry in
                    let wheelSize = geometry.size.width * 1.4

                    ZStack {
                        Ellipse()
                            .fill(Color.black.opacity(0.16))
                            .frame(width: wheelSize * 0.72, height: 38)
                            .blur(radius: 14)
                            .offset(y: 284)

                        recipeTurntableWheel
                            .frame(width: wheelSize, height: wheelSize)
                            .padding(16)
                            .drawingGroup(opaque: false, colorMode: .nonLinear)
                            .rotationEffect(.degrees(wheelRotation))
                            .padding(-16)
                            .offset(x: 0, y: 122)
                            .frame(width: 370, height: 304)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .shadow(color: .black.opacity(0.2), radius: 18, y: 10)

                        wheelPointerAndButton
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .clipped()
                }
                .frame(height: 340)
            }
        }
    }

    private var wheelPointerAndButton: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [.black, Color.black.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 20, height: 106)
                .overlay(Triangle().stroke(Color.yellow, lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 10, y: 3)

            Button {
                toggleWheelSpin()
            } label: {
                Text(isSpinning ? "Stop" : "Start")
                    .font(.title3.weight(.black))
                    .foregroundColor(isSpinning ? .yellow : .black)
                    .frame(width: 102, height: 102)
                    .background(
                        RadialGradient(
                            colors: isSpinning
                            ? [Color.black.opacity(0.82), .black]
                            : [Color.yellow.opacity(0.92), .yellow],
                            center: .topLeading,
                            startRadius: 12,
                            endRadius: 82
                        )
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black, lineWidth: 5))
                    .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 2).padding(8))
                    .scaleEffect(isSpinning ? 1.05 : 1)
                    .shadow(color: .black.opacity(0.24), radius: 14, y: 7)
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.24, dampingFraction: 0.7), value: isSpinning)
            .offset(y: -10)
        }
        .offset(x: 0, y: 48)
    }

    private var fadedEmptyRecipeWheel: some View {
        GeometryReader { geometry in
            let wheelSize = min(geometry.size.width * 1.4, 520)

            ZStack {
                Circle().fill(Color.white)
                Circle().stroke(Color.black, lineWidth: 9).padding(2)
                Circle().stroke(Color.yellow, lineWidth: 26).padding(10)
                Circle().stroke(Color.black, lineWidth: 6).padding(24)
                Circle().fill(Color(.systemGray5)).padding(wheelSize * 0.25)
            }
            .frame(width: wheelSize, height: wheelSize)
            .offset(y: 130)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
        }
        .frame(height: 340)
    }

    private var recipeTurntableWheel: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size * 0.38
            let segments = recipeWheelSegments(for: wheelRecipes)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, Color(.systemGray6), Color(.systemGray4)],
                            center: .center,
                            startRadius: size * 0.08,
                            endRadius: size * 0.58
                        )
                    )
                Circle().stroke(Color.black, lineWidth: 9).padding(2)
                Circle().stroke(Color.yellow, lineWidth: 26).padding(10)
                Circle().stroke(Color.black, lineWidth: 6).padding(24)

                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let fullLabelScale = wheelLabelScale(
                        segmentAngle: segment.endAngle - segment.startAngle,
                        radius: radius,
                        preferredHeight: 78
                    )
                    let tagScale = wheelLabelScale(
                        segmentAngle: segment.endAngle - segment.startAngle,
                        radius: radius,
                        preferredHeight: 30
                    )

                    WheelSegmentShape(
                        startAngle: .degrees(segment.startAngle),
                        endAngle: .degrees(segment.endAngle),
                        innerRadiusRatio: 0.55
                    )
                    .fill(segmentFill(for: index))
                    .overlay(
                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle),
                            innerRadiusRatio: 0.55
                        )
                        .stroke(Color.black, lineWidth: 6)
                    )

                    if fullLabelScale >= minimumReadableWheelLabelScale {
                        RecipeWheelSegmentLabel(recipe: segment.recipe, showsTitle: true)
                            .frame(width: min(105, size * 0.2))
                            .scaleEffect(fullLabelScale)
                            .rotationEffect(.degrees(labelRotation(for: segment.midAngle)))
                            .offset(
                                x: cos(segment.midAngle * .pi / 180) * radius,
                                y: sin(segment.midAngle * .pi / 180) * radius
                            )
                            .frame(width: size, height: size)
                            .clipShape(
                                WheelSegmentShape(
                                    startAngle: .degrees(segment.startAngle),
                                    endAngle: .degrees(segment.endAngle),
                                    innerRadiusRatio: 0.55
                                )
                            )
                            .allowsHitTesting(false)
                    } else if tagScale >= minimumReadableWheelLabelScale {
                        RecipeWheelSegmentLabel(recipe: segment.recipe, showsTitle: false)
                            .frame(width: min(82, size * 0.16))
                            .scaleEffect(tagScale)
                            .rotationEffect(.degrees(labelRotation(for: segment.midAngle)))
                            .offset(
                                x: cos(segment.midAngle * .pi / 180) * radius,
                                y: sin(segment.midAngle * .pi / 180) * radius
                            )
                            .frame(width: size, height: size)
                            .clipShape(
                                WheelSegmentShape(
                                    startAngle: .degrees(segment.startAngle),
                                    endAngle: .degrees(segment.endAngle),
                                    innerRadiusRatio: 0.55
                                )
                            )
                            .allowsHitTesting(false)
                    }
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, Color(.systemGray6)],
                            center: .topLeading,
                            startRadius: size * 0.08,
                            endRadius: size * 0.25
                        )
                    )
                    .padding(size * 0.34)
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
                Circle().stroke(Color.black, lineWidth: 5).padding(size * 0.25)
                Circle().stroke(Color.yellow, lineWidth: 8).padding(size * 0.235)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var turntableWheel: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size * 0.38
            let segments = wheelSegments(
                for: wheelIngredients,
                expiryFirst: wheelUsesExpiryWeighting
            )

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, Color(.systemGray6), Color(.systemGray4)],
                            center: .center,
                            startRadius: size * 0.08,
                            endRadius: size * 0.58
                        )
                    )

                Circle()
                    .stroke(Color.black, lineWidth: 9)
                    .padding(2)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.yellow, Color(red: 1.0, green: 0.82, blue: 0.05), .yellow, .white, .yellow],
                            center: .center
                        ),
                        lineWidth: 26
                    )
                    .padding(10)

                Circle()
                    .stroke(Color.black, lineWidth: 6)
                    .padding(24)

                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let fullLabelScale = wheelLabelScale(
                        segmentAngle: segment.endAngle - segment.startAngle,
                        radius: radius,
                        preferredHeight: 78
                    )
                    let tagScale = wheelLabelScale(
                        segmentAngle: segment.endAngle - segment.startAngle,
                        radius: radius,
                        preferredHeight: 30
                    )

                    WheelSegmentShape(
                        startAngle: .degrees(segment.startAngle),
                        endAngle: .degrees(segment.endAngle),
                        innerRadiusRatio: 0.55
                    )
                    .fill(segmentFill(for: index))
                    .overlay(
                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle),
                            innerRadiusRatio: 0.55
                        )
                        .stroke(Color.black, lineWidth: 6)
                    )
                    .overlay(
                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle),
                            innerRadiusRatio: 0.55
                        )
                        .stroke(Color.white.opacity(0.38), lineWidth: 1.5)
                        .padding(5)
                    )

                    if fullLabelScale >= minimumReadableWheelLabelScale {
                        WheelSegmentLabel(ingredient: segment.ingredient, showsName: true)
                            .frame(width: min(92, size * 0.18))
                            .scaleEffect(fullLabelScale)
                            .rotationEffect(.degrees(labelRotation(for: segment.midAngle)))
                            .offset(
                                x: cos(segment.midAngle * .pi / 180) * radius,
                                y: sin(segment.midAngle * .pi / 180) * radius
                            )
                            .frame(width: size, height: size)
                            .clipShape(
                                WheelSegmentShape(
                                    startAngle: .degrees(segment.startAngle),
                                    endAngle: .degrees(segment.endAngle),
                                    innerRadiusRatio: 0.55
                                )
                            )
                            .allowsHitTesting(false)
                    } else if tagScale >= minimumReadableWheelLabelScale {
                        WheelSegmentLabel(ingredient: segment.ingredient, showsName: false)
                            .frame(width: min(72, size * 0.14))
                            .scaleEffect(tagScale)
                            .rotationEffect(.degrees(labelRotation(for: segment.midAngle)))
                            .offset(
                                x: cos(segment.midAngle * .pi / 180) * radius,
                                y: sin(segment.midAngle * .pi / 180) * radius
                            )
                            .frame(width: size, height: size)
                            .clipShape(
                                WheelSegmentShape(
                                    startAngle: .degrees(segment.startAngle),
                                    endAngle: .degrees(segment.endAngle),
                                    innerRadiusRatio: 0.55
                                )
                            )
                            .allowsHitTesting(false)
                    }
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, Color(.systemGray6)],
                            center: .topLeading,
                            startRadius: size * 0.08,
                            endRadius: size * 0.25
                        )
                    )
                    .padding(size * 0.34)
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

                Circle()
                    .stroke(Color.black, lineWidth: 5)
                    .padding(size * 0.25)

                Circle()
                    .stroke(Color.yellow, lineWidth: 8)
                    .padding(size * 0.235)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func segmentFill(for index: Int) -> AnyShapeStyle {
        let colors: [Color] = index.isMultiple(of: 2)
        ? [Color.white, Color(.systemGray6), Color(red: 0.93, green: 0.94, blue: 0.97)]
        : [Color(red: 0.91, green: 0.92, blue: 0.96), Color(.systemGray5), Color.white]

        return AnyShapeStyle(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func wheelSegments(
        for ingredients: [Ingredient],
        expiryFirst: Bool
    ) -> [WeightedWheelSegment] {
        guard !ingredients.isEmpty else { return [] }

        let weights = ingredients.map {
            expiryFirst ? expiryWeight(for: $0) : 1
        }
        let totalWeight = weights.reduce(0, +)
        let arcSizes = weights.map { ($0 / totalWeight) * 360 }
        var startAngle = -90 - ((arcSizes.first ?? 0) / 2)

        return zip(ingredients, arcSizes).map { ingredient, arcSize in
            defer { startAngle += arcSize }
            return WeightedWheelSegment(
                ingredient: ingredient,
                startAngle: startAngle,
                endAngle: startAngle + arcSize
            )
        }
    }

    private func recipeWheelSegments(for recipes: [Recipe]) -> [RecipeWheelSegment] {
        guard !recipes.isEmpty else { return [] }

        let arcSize = 360.0 / Double(recipes.count)
        var startAngle = -90 - (arcSize / 2)

        return recipes.map { recipe in
            defer { startAngle += arcSize }
            return RecipeWheelSegment(
                recipe: recipe,
                startAngle: startAngle,
                endAngle: startAngle + arcSize
            )
        }
    }

    private func expiryWeight(for ingredient: Ingredient) -> Double {
        guard let expiryDate = ingredient.expiryDate else { return 1 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDay = calendar.startOfDay(for: expiryDate)
        let days = calendar.dateComponents([.day], from: today, to: expiryDay).day ?? 30

        switch days {
        case ...0: return 4
        case 1: return 3.5
        case 2: return 3
        case 3: return 2.6
        case 4: return 2.2
        case 5: return 2
        case 6: return 1.8
        case 7: return 1.6
        case 8...14: return 1.3
        default: return 1
        }
    }

    private func angle(_ angle: Double, isWithinStart start: Double, end: Double) -> Bool {
        let offsetFromStart = normalizedDegrees(angle - start)
        return offsetFromStart < (end - start)
    }

    private func recipeSelection(from recipes: [Recipe]) -> Recipe? {
        guard !recipes.isEmpty else { return nil }

        let segments = recipeWheelSegments(for: recipes)
        let localPointerAngle = normalizedDegrees(-90 - wheelRotation)

        return segments.first { segment in
            angle(localPointerAngle, isWithinStart: segment.startAngle, end: segment.endAngle)
        }?.recipe ?? segments.last?.recipe
    }

    private func toggleWheelSpin() {
        if isSpinning {
            isSpinning = false
            stopSpinTimer()
            remainingSpins = max(remainingSpins - 1, 0)

            if selectedMode == .dishes {
                selectedDishRecipe = recipeSelection(from: wheelRecipes)
            } else {
                let stoppedWheelIngredients = wheelIngredients
                if let selectedIngredient = wheelSelection(from: stoppedWheelIngredients) {
                    vm.addSelection(selectedIngredient)
                }
            }

            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                activeControlPanel = .results
            }
        } else if remainingSpins > 0 {
            if selectedMode == .dishes {
                let nextWheelRecipes = appVM.savedRecipesVM.savedRecipes
                guard !nextWheelRecipes.isEmpty else { return }
                wheelRecipeSnapshot = nextWheelRecipes
            } else {
                let nextWheelIngredients = availableWheelIngredients
                guard !nextWheelIngredients.isEmpty else { return }
                wheelIngredientSnapshot = nextWheelIngredients
                wheelExpiryModeSnapshot = isExpiredFirstEnabled
            }

            isSpinning = true
            startSpinTimer()
        }
    }

    private func startSpinTimer() {
        stopSpinTimer()

        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            wheelRotation = normalizedDegrees(wheelRotation + 8)
        }
    }

    private func stopSpinTimer() {
        spinTimer?.invalidate()
        spinTimer = nil
    }

    private func resetRound() {
        stopSpinTimer()
        isSpinning = false
        remainingSpins = 3
        vm.clearResults()
        wheelIngredientSnapshot = []
        wheelRecipeSnapshot = []
        wheelExpiryModeSnapshot = nil
        selectedDishRecipe = nil
    }

    private func switchMode(to mode: Mode) {
        guard selectedMode != mode else { return }

        stopSpinTimer()
        isSpinning = false
        selectedMode = mode
        remainingSpins = 3
        vm.clearResults()
        wheelIngredientSnapshot = []
        wheelRecipeSnapshot = []
        wheelExpiryModeSnapshot = nil
        selectedDishRecipe = nil
        activeControlPanel = .selection
    }

    private func removeSelectedResult(_ ingredient: Ingredient) {
        let resultCount = vm.selectedResults.count
        vm.removeResult(ingredient)

        if vm.selectedResults.count < resultCount {
            remainingSpins = min(remainingSpins + 1, 3)
        }
    }

    private func updateMagicAnimation(isLoading: Bool) {
        if isLoading {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                magicPulse = true
            }

            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                magicRotation = 360
            }
        } else {
            magicPulse = false
            magicRotation = 0
        }
    }

    private func toggleComboCategory(_ category: IngredientCategory) {
        if selectedComboCategories.contains(category) {
            if selectedComboCategories.count > 1 {
                selectedComboCategories.remove(category)
            }
        } else {
            selectedComboCategories.insert(category)
        }
    }

    private func normalizedDegrees(_ degrees: Double) -> Double {
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        return remainder >= 0 ? remainder : remainder + 360
    }

    private var minimumReadableWheelLabelScale: CGFloat {
        0.72
    }

    private func wheelLabelScale(
        segmentAngle: Double,
        radius: CGFloat,
        preferredHeight: CGFloat
    ) -> CGFloat {
        let arcLength = radius * CGFloat(segmentAngle * .pi / 180)
        let availableTangentialSpace = max(arcLength - 12, 0)
        return min(availableTangentialSpace / preferredHeight, 1)
    }

    private func labelRotation(for angle: Double) -> Double {
        let normalizedAngle = normalizedDegrees(angle)
        if normalizedAngle > 90 && normalizedAngle < 270 {
            return angle + 180
        }

        return angle
    }
}

private struct PreferenceBasketSheet: View {
    @ObservedObject var vm: DishRollerViewModel
    let storageIngredients: [Ingredient]

    private var availableIngredients: [Ingredient] {
        var seenNames: Set<String> = []

        return storageIngredients
            .filter { $0.amount > 0 }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            .filter { ingredient in
                let key = selectionKey(for: ingredient)
                guard !seenNames.contains(key) else { return false }
                seenNames.insert(key)
                return true
            }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Preference Basket")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.top, 22)
                    .padding(.bottom, 10)

                HStack {
                    Text("\(vm.selectedResults.count)/5 selected")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Color.yellow)
                        .clipShape(Capsule())

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)

                Group {
                    if availableIngredients.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "basket")
                                .font(.system(size: 42, weight: .black))
                                .foregroundStyle(.gray)

                            Text("No ingredients in Storage")
                                .font(.headline.weight(.black))

                            Text("Add food to Storage before using the preference basket.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            Section {
                                ForEach(availableIngredients) { ingredient in
                                    preferenceRow(ingredient)
                                        .listRowBackground(Color.white)
                                }
                            } header: {
                                Text("Tap + to add an ingredient to Results. Tap − to remove it.")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.black.opacity(0.65))
                                    .textCase(nil)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.98))
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func preferenceRow(_ ingredient: Ingredient) -> some View {
        let selectedIngredient = selectedIngredient(matching: ingredient)
        let isSelected = selectedIngredient != nil

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.black)

                Text(ingredient.category.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)
            }

            Spacer()

            dashedControl(systemName: "minus", isEnabled: isSelected) {
                guard let selectedIngredient else { return }
                vm.removeResult(selectedIngredient)
            }

            dashedControl(
                systemName: "plus",
                isEnabled: !isSelected && vm.selectedResults.count < 5
            ) {
                vm.addSelection(ingredient)
            }
        }
        .padding(.vertical, 5)
    }

    private func dashedControl(
        systemName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.black))
                .foregroundStyle(isEnabled ? Color.black : Color.gray.opacity(0.45))
                .frame(width: 38, height: 38)
                .overlay(
                    Circle()
                        .stroke(
                            isEnabled ? Color.black : Color.gray.opacity(0.35),
                            style: StrokeStyle(lineWidth: 1.8, dash: [5, 4])
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func selectedIngredient(matching ingredient: Ingredient) -> Ingredient? {
        let key = selectionKey(for: ingredient)
        return vm.selectedResults.first { selectionKey(for: $0) == key }
    }

    private func selectionKey(for ingredient: Ingredient) -> String {
        ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private struct LocalSelectionMenu<Option: Hashable>: View {
    let title: String
    let options: [Option]
    let label: KeyPath<Option, String>
    let onSelection: (Option) -> Void

    @State private var selection: Option

    init(
        title: String,
        initialSelection: Option,
        options: [Option],
        label: KeyPath<Option, String>,
        onSelection: @escaping (Option) -> Void
    ) {
        self.title = title
        self.options = options
        self.label = label
        self.onSelection = onSelection
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option[keyPath: label]) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            selection = option
                            onSelection(option)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selection[keyPath: label])
                        .font(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.white)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlowResultView: View {
    let results: [Ingredient]
    let onRemove: (Ingredient) -> Void

    var body: some View {
        let isCompact = results.count >= 4

        ResultFlowLayout(
            spacing: isCompact ? 5 : 8,
            lineSpacing: isCompact ? 5 : 8
        ) {
            ForEach(results) { ingredient in
                Button {
                    onRemove(ingredient)
                } label: {
                    HStack(alignment: .center, spacing: isCompact ? 4 : 6) {
                        Text(ingredient.name)
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)
                            .allowsTightening(true)
                            .multilineTextAlignment(.leading)

                        Image(systemName: "xmark")
                            .font((isCompact ? Font.caption2 : Font.caption).weight(.bold))
                    }
                    .font(isCompact ? .system(size: 12) : .headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, isCompact ? 9 : 16)
                    .padding(.vertical, isCompact ? 6 : 8)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: isCompact ? 14 : 18))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


struct ResultFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var measuredWidth: CGFloat = 0

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)

            if maxWidth > 0, size.width > maxWidth {
                size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            }

            if maxWidth > 0, currentX > 0, currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + lineSpacing
                lineHeight = 0
                size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            }

            measuredWidth = max(measuredWidth, currentX + size.width)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(
            width: maxWidth > 0 ? maxWidth : measuredWidth,
            height: currentY + lineHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0
        let maxWidth = bounds.width

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)

            if size.width > maxWidth {
                size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            }

            if currentX > bounds.minX, currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + lineSpacing
                lineHeight = 0
                size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct WheelSegmentShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadiusRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRadiusRatio

        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

struct WheelSegmentLabel: View {
    let ingredient: Ingredient
    let showsName: Bool

    var body: some View {
        VStack(spacing: 7) {
            Text(ingredient.category.rawValue)
                .font(.caption2)
                .fontWeight(.black)
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [.yellow, Color(red: 1.0, green: 0.84, blue: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black, lineWidth: 1.4)
                )
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)

            if showsName {
                Text(ingredient.name)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct RecipeWheelSegmentLabel: View {
    let recipe: Recipe
    let showsTitle: Bool

    var body: some View {
        VStack(spacing: 7) {
            Text(recipe.estimatedTime.uppercased())
                .font(.caption2)
                .fontWeight(.black)
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [.yellow, Color(red: 1.0, green: 0.84, blue: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black, lineWidth: 1.4)
                )

            if showsTitle {
                Text(recipe.title)
                    .font(.subheadline)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private extension IngredientCategory {
    var menuTitle: String {
        switch self {
        case .meat:
            "Meat"
        case .seafood:
            "Seafood"
        case .veg:
            "Veg"
        case .drink:
            "Drink"
        case .condiment:
            "Condiment"
        case .other:
            "Other"
        }
    }
}

#Preview {
    DishRollerView()
        .environmentObject(AppViewModel())
}
