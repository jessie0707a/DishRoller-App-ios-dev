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

    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var vm = DishRollerViewModel()
    @State private var selectedMode: Mode = .raw

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                controlPanel
                modeBar
                wheelView
            }
            .padding()
        }
        .alert("Notice", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { _ in vm.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Text("DishRoller")
                .font(.largeTitle)
                .fontWeight(.black)

            Spacer()

            Image(systemName: "exclamationmark.circle.fill")
                .font(.title)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Color.yellow)
                .clipShape(Capsule())
        }
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 18) {
                HStack(alignment: .center, spacing: 14) {
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

                HStack(alignment: .center, spacing: 14) {
                    selectionGroup(
                        title: "Flavour",
                        titleMinWidth: 68,
                        titleView: { Text(vm.selectedStyle.rawValue) }
                    ) {
                        ForEach(FlavourStyle.allCases) { style in
                            Button(style.rawValue) {
                                vm.selectedStyle = style
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        preferenceCapsule
                        addIngredientButton
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .background(Color.black)

            VStack(alignment: .leading, spacing: 18) {
                Text("Results:")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundColor(.black)

                FlowResultView(results: vm.selectedResults) { ingredient in
                    vm.removeResult(ingredient)
                }
                .frame(minHeight: 46, alignment: .leading)

                HStack(spacing: 24) {
                    Button {
                        Task {
                            if let recipe = await vm.generateRecipe() {
                                appVM.openMenu(with: recipe)
                            }
                        }
                    } label: {
                        Text(vm.isLoading ? "Loading..." : "Generate")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.black)
                            .clipShape(Capsule())
                    }
                    .disabled(vm.selectedResults.isEmpty || vm.isLoading)

                    Button {
                        vm.clearResults()
                    } label: {
                        Text("Clear")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding(18)
            .background(Color.yellow)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var preferenceCapsule: some View {
        HStack {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Color.white)
        .clipShape(Capsule())
    }

    private var addIngredientButton: some View {
        Button {
            vm.roll(from: appVM.storageVM.ingredients)
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
                .background(Color.yellow)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
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
                .font(.title3)
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
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.white)
            .clipShape(Capsule())
        }
    }
    

    private var modeBar: some View {
        HStack {
            Text("Modes:")
                .font(.title)
                .fontWeight(.black)

            Spacer()

            HStack(spacing: 4) {
                ForEach(Mode.allCases) { mode in
                    Button {
                        selectedMode = mode
                    } label: {
                        Text(mode.rawValue)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(selectedMode == mode ? .black : .yellow)
                            .lineLimit(1)
                            .frame(minWidth: 72)
                            .frame(height: 36)
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

    private var wheelView: some View {
        VStack(spacing: 20) {
            ForEach(appVM.storageVM.ingredients.prefix(5)) { ingredient in
                Text(ingredient.name)
                    .font(.title2)
                    .fontWeight(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Button {
                vm.roll(from: appVM.storageVM.ingredients)
            } label: {
                Text("Start")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .padding(34)
                    .background(Color.yellow)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 8)
                    )
            }
        }
    }
}

struct FlowResultView: View {
    let results: [Ingredient]
    let onRemove: (Ingredient) -> Void

    var body: some View {
        HStack {
            ForEach(results) { ingredient in
                Button {
                    onRemove(ingredient)
                } label: {
                    HStack {
                        Text(ingredient.name)
                        Image(systemName: "xmark")
                    }
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

#Preview {
    DishRollerView()
        .environmentObject(AppViewModel())
}
