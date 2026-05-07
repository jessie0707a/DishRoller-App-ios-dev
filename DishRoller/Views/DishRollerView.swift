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

    private let comboCategories: [IngredientCategory] = [.meat, .seafood, .veg]

    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = DishRollerViewModel()
    @State private var selectedMode: Mode = .raw
    @State private var isSpinning = false
    @State private var wheelRotation = 0.0
    @State private var spinTimer: Timer?
    @State private var remainingSpins = 3
    @State private var selectedComboCategories: Set<IngredientCategory> = [.meat, .seafood, .veg]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                controlPanel
                modeBar
                wheelView
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .alert("Notice", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { _ in vm.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onDisappear {
            stopSpinTimer()
        }
    }

    private var header: some View {
        HStack {
            Text("DishRoller")
                .font(.system(size: 26, weight: .black))
                .fontWeight(.black)

            Spacer()

            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3.weight(.bold))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.yellow)
                .clipShape(Capsule())
        }
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    selectionGroup(
                        title: "Time",
                        titleMinWidth: 46,
                        titleView: { Text(vm.selectedTime.rawValue) }
                    ) {
                        ForEach(CookingTime.allCases) { time in
                            Button(time.rawValue) {
                                vm.selectedTime = time
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    selectionGroup(
                        title: "Type",
                        titleMinWidth: 42,
                        titleView: { Text(vm.selectedType.rawValue) }
                    ) {
                        ForEach(DishType.allCases) { type in
                            Button(type.rawValue) {
                                vm.selectedType = type
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(alignment: .center, spacing: 10) {
                    selectionGroup(
                        title: "Flavour",
                        titleMinWidth: 60,
                        titleView: { Text(vm.selectedStyle.rawValue) }
                    ) {
                        ForEach(FlavourStyle.allCases) { style in
                            Button(style.rawValue) {
                                vm.selectedStyle = style
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        preferenceCapsule
                        addIngredientButton
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                comboSelectionGroup
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(Color.black)

            VStack(alignment: .leading, spacing: 12) {
                Text("Results:")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)

                FlowResultView(results: vm.selectedResults) { ingredient in
                    vm.removeResult(ingredient)
                }
                .frame(minHeight: 46, alignment: .leading)

                HStack(spacing: 16) {
                    Button {
                        Task {
                            if let recipe = await vm.generateRecipe() {
                                appVM.openMenu(with: recipe)
                            }
                        }
                    } label: {
                        Text(vm.isLoading ? "Loading..." : "Generate")
                            .font(.subheadline)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.black)
                            .clipShape(Capsule())
                    }
                    .disabled(vm.selectedResults.isEmpty || vm.isLoading)

                    Button {
                        resetRound()
                    } label: {
                        Text("Clear")
                            .font(.subheadline)
                            .fontWeight(.black)
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
                }
            }
            .padding(14)
            .background(Color.yellow)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var preferenceCapsule: some View {
        HStack {
            Text("Preferences")
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(Color.white)
        .clipShape(Capsule())
    }

    private var addIngredientButton: some View {
        Button {
            vm.roll(from: wheelIngredients)
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(Color.yellow)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
        }
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
                            selectedMode = mode
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

    private var wheelIngredients: [Ingredient] {
        appVM.storageVM.ingredients.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        .filter {
            selectedComboCategories.contains($0.category)
        }
    }

    private var comboSelectionTitle: String {
        let orderedSelections = comboCategories.filter { selectedComboCategories.contains($0) }
        guard !orderedSelections.isEmpty else { return "Select tags" }
        return orderedSelections.map(\.menuTitle).joined(separator: ", ")
    }

    private var currentWheelSelection: Ingredient? {
        guard !wheelIngredients.isEmpty else { return nil }
        guard wheelIngredients.count > 1 else { return wheelIngredients[0] }

        let segmentAngle = 360.0 / Double(wheelIngredients.count)
        let pointerAngle = normalizedDegrees((segmentAngle / 2) - wheelRotation)
        let index = Int(pointerAngle / segmentAngle) % wheelIngredients.count
        return wheelIngredients[index]
    }

    private var wheelView: some View {
        VStack(spacing: 12) {
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
                    let wheelSize = geometry.size.width * 1.45

                    ZStack {
                        turntableWheel
                            .rotationEffect(.degrees(wheelRotation))
                            .frame(width: wheelSize, height: wheelSize)
                            .offset(x:-70, y:8)

                        VStack(spacing: 0) {
                            Triangle()
                                .fill(Color.black)
                                .frame(width: 16, height: 84)
                                .shadow(color: .black.opacity(0.18), radius: 4, y: 1)

                            Button {
                                toggleWheelSpin()
                            } label: {
                                Text(isSpinning ? "Stop" : "Start")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(isSpinning ? .yellow : .black)
                                    .frame(width: 102, height: 102)
                                    .background(isSpinning ? Color.black : Color.yellow)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 5)
                                    )
                                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                            .offset(y: -10)
                        }
                        .offset(x:-70,y:-30)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .clipped()
                }
                .frame(height: 340)
            }
        }
    }

    private var turntableWheel: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size * 0.31
            let segmentAngle = 360.0 / Double(wheelIngredients.count)

            ZStack {
                Circle()
                    .fill(Color.white)

                Circle()
                    .stroke(Color.yellow, lineWidth: 30)
                    .padding(6)

                ForEach(Array(wheelIngredients.enumerated()), id: \.element.id) { index, ingredient in
                    let startAngle = -90.0 - (segmentAngle / 2) + (Double(index) * segmentAngle)
                    let endAngle = startAngle + segmentAngle
                    let midAngle = startAngle + (segmentAngle / 2)

                    WheelSegmentShape(
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(endAngle),
                        innerRadiusRatio: 0.34
                    )
                    .fill(index.isMultiple(of: 2) ? Color(.systemGray6) : Color(.systemGray5))
                    .overlay(
                        WheelSegmentShape(
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(endAngle),
                            innerRadiusRatio: 0.34
                        )
                        .stroke(Color.black, lineWidth: 4)
                    )

                    WheelSegmentLabel(ingredient: ingredient)
                        .frame(width: 92)
                        .rotationEffect(.degrees(labelRotation(for: midAngle)))
                        .offset(
                            x: cos(midAngle * .pi / 180) * radius,
                            y: sin(midAngle * .pi / 180) * radius
                        )
                }

                Circle()
                    .fill(Color.white)
                    .padding(size * 0.34)

                Circle()
                    .stroke(Color.yellow, lineWidth: 6)
                    .padding(size * 0.34)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func toggleWheelSpin() {
        guard !wheelIngredients.isEmpty else { return }

        if isSpinning {
            isSpinning = false
            stopSpinTimer()
            remainingSpins = max(remainingSpins - 1, 0)

            if let selectedIngredient = currentWheelSelection {
                vm.addSelection(selectedIngredient)
            }
        } else if remainingSpins > 0 {
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

    private func labelRotation(for angle: Double) -> Double {
        let normalizedAngle = normalizedDegrees(angle)
        if normalizedAngle > 90 && normalizedAngle < 270 {
            return angle + 180
        }

        return angle
    }
}

struct FlowResultView: View {
    let results: [Ingredient]
    let onRemove: (Ingredient) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(results) { ingredient in
                    Button {
                        onRemove(ingredient)
                    } label: {
                        HStack(spacing: 6) {
                            Text(ingredient.name)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Image(systemName: "xmark")
                                .font(.caption.weight(.bold))
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                    }
                }
            }
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

    var body: some View {
        VStack(spacing: 6) {
            Text(ingredient.category.rawValue)
                .font(.caption2)
                .fontWeight(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.yellow)
                .clipShape(Capsule())

            Text(ingredient.name)
                .font(.headline)
                .fontWeight(.black)
                .foregroundColor(.black)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
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
        }
    }
}

#Preview {
    DishRollerView()
        .environmentObject(AppViewModel())
}
