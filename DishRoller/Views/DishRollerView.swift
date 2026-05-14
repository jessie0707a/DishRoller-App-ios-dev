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
    @State private var magicPulse = false
    @State private var magicRotation = 0.0
    @State private var storageNoticeMessage: String?
    @State private var storageNoticeTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    controlPanel
                    modeBar
                    wheelView
                        .padding(.top,-20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 14)
            }
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
        .overlay(alignment: .top) {
            if let storageNoticeMessage {
                storageNoticeCard(message: storageNoticeMessage)
                    .padding(.top, 88)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: vm.isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.86), value: storageNoticeMessage)
        .alert("Notice", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { _ in vm.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onChange(of: vm.isLoading) { _, isLoading in
            updateMagicAnimation(isLoading: isLoading)
        }
        .onDisappear {
            stopSpinTimer()
            storageNoticeTask?.cancel()
            updateMagicAnimation(isLoading: false)
        }
    }

    private var header: some View {
        HStack {
            Text("DishRoller")
                .font(.system(size: 26, weight: .black))
                .fontWeight(.black)

            Spacer()

            NavigationLink {
                AvoidancePreferencesView()
                    .environmentObject(appVM)
            } label: {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Avoid Foods")
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
                            if let recipe = await vm.generateRecipe(
                                avoidancePrompt: appVM.avoidanceVM.selectedAvoidancePrompt
                            ) {
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

    private func storageNoticeCard(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.black)
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
    }

    private var preferenceCapsule: some View {
        TextField("Preferences", text: $vm.customPreferences)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.black)
            .lineLimit(1)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(false)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Color.white)
            .clipShape(Capsule())
            .accessibilityLabel("Recipe preferences")
            .onSubmit(addPreferredIngredient)
    }

    private var addIngredientButton: some View {
        Button {
            addPreferredIngredient()
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

    private func addPreferredIngredient() {
        if vm.addPreferredIngredient(named: vm.customPreferences, from: appVM.storageVM.ingredients) {
            vm.customPreferences = ""
        } else {
            showStorageNotice("sorry, it was out of storage")
        }
    }

    private func showStorageNotice(_ message: String) {
        storageNoticeTask?.cancel()
        storageNoticeMessage = message

        storageNoticeTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            storageNoticeMessage = nil
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
                        turntableWheel
                            .rotationEffect(.degrees(wheelRotation))
                            .frame(width: wheelSize, height: wheelSize)
                            .offset(x:0, y:125)
                            .frame(width:370,height:300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        VStack(spacing: 0) {
                            Triangle()
                                .fill(Color.black)
                                .frame(width: 16, height: 100)
                                .shadow(color: .black.opacity(0.18), radius: 8, y: 1)

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
                        .offset(x:0,y:50)
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
            let radius = size * 0.38
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
                        innerRadiusRatio: 0.55
                    )
                    .fill(index.isMultiple(of: 2) ? Color(.systemGray6) : Color(.systemGray5))
                    .overlay(
                        WheelSegmentShape(
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(endAngle),
                            innerRadiusRatio: 0.55
                        )
                        .stroke(Color.black, lineWidth: 8)
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
                    .padding(size * 0.235)
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
        ResultFlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(results) { ingredient in
                Button {
                    onRemove(ingredient)
                } label: {
                    HStack(alignment: .top, spacing: 6) {
                        Text(ingredient.name)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .padding(.top, 3)
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
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
            let availableWidth = max(maxWidth - currentX, 0)
            let proposedWidth = maxWidth > 0 ? availableWidth : nil
            var size = subview.sizeThatFits(ProposedViewSize(width: proposedWidth, height: nil))

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
            let availableWidth = max(bounds.maxX - currentX, 0)
            var size = subview.sizeThatFits(ProposedViewSize(width: availableWidth, height: nil))

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
        }
    }
}

#Preview {
    DishRollerView()
        .environmentObject(AppViewModel())
}
