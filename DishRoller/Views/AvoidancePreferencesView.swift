//
//  AvoidancePreferencesView.swift
//  DishRoller
//

import SwiftUI

struct AvoidancePreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appVM: AppViewModel

    var body: some View {
        List {
            Section {
                Button {
                    appVM.avoidanceVM.addProfile()
                } label: {
                    Label("Add avoid card", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(appVM.avoidanceVM.profiles) { profile in
                    AvoidanceProfileCard(
                        profile: profile,
                        onToggle: { appVM.avoidanceVM.toggleSelection(for: profile) },
                        onNameChange: { appVM.avoidanceVM.updateName(for: profile, name: $0) },
                        onFoodsChange: { appVM.avoidanceVM.updateAvoidFoods(for: profile, avoidFoods: $0) }
                    )
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            appVM.avoidanceVM.deleteProfile(profile)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(avoidancePageBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            avoidancePageHeader
        }
    }

    private var avoidancePageHeader: some View {
        ZStack {
            Text("Avoid Foods")
                .font(.headline.weight(.black))
                .foregroundStyle(.black)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.yellow)
                        .frame(width: 48, height: 48)
                        .background(Color.black)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 1, green: 0.82, blue: 0.05))
    }

    private var avoidancePageBackground: some View {
        ZStack {
            Color(red: 1, green: 0.82, blue: 0.05)

            Image("shopping-food-pattern")
                .resizable()
                .scaledToFill()
                .opacity(0.24)

            Color.yellow.opacity(0.12)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct AvoidanceProfileCard: View {
    let profile: AvoidanceProfile
    let onToggle: () -> Void
    let onNameChange: (String) -> Void
    let onFoodsChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: profile.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2.weight(.bold))
                        .foregroundColor(profile.isSelected ? .yellow : .gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(profile.isSelected ? "Selected" : "Not selected")

                VStack(alignment: .leading, spacing: 6) {
                    TextField(
                        "Name",
                        text: Binding(
                            get: { profile.personName },
                            set: onNameChange
                        )
                    )
                    .font(.headline)
                    .fontWeight(.black)
                    .textInputAutocapitalization(.words)

                    TextField(
                        "Foods to avoid, separated by commas",
                        text: Binding(
                            get: { profile.avoidFoods },
                            set: onFoodsChange
                        ),
                        axis: .vertical
                    )
                    .font(.subheadline)
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.sentences)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(profile.isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    NavigationStack {
        AvoidancePreferencesView()
            .environmentObject(AppViewModel())
    }
}
