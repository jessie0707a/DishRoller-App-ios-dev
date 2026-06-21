//
//  AvoidancePreferencesViewModel.swift
//  DishRoller
//

import Combine
import Foundation

final class AvoidancePreferencesViewModel: ObservableObject {
    @Published var profiles: [AvoidanceProfile] = []

    init() {
        profiles = StorageService.shared.loadAvoidanceProfiles()
    }

    var selectedAvoidancePrompt: String {
        profiles
            .filter { $0.isSelected }
            .compactMap { profile in
                let foods = profile.avoidFoods.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !foods.isEmpty else { return nil }

                let name = profile.personName.trimmingCharacters(in: .whitespacesAndNewlines)
                return name.isEmpty ? foods : "\(name): \(foods)"
            }
            .joined(separator: "; ")
    }

    var selectedProfileCount: Int {
        profiles.filter {
            $0.isSelected
                && !$0.avoidFoods.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    func addProfile() {
        profiles.insert(AvoidanceProfile(), at: 0)
        persist()
    }

    func updateName(for profile: AvoidanceProfile, name: String) {
        update(profile) { $0.personName = name }
    }

    func updateAvoidFoods(for profile: AvoidanceProfile, avoidFoods: String) {
        update(profile) {
            $0.avoidFoods = avoidFoods
            if avoidFoods.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                $0.isSelected = false
            }
        }
    }

    func toggleSelection(for profile: AvoidanceProfile) {
        let foods = profile.avoidFoods.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !foods.isEmpty else { return }
        update(profile) { $0.isSelected.toggle() }
    }

    func deleteProfile(_ profile: AvoidanceProfile) {
        profiles.removeAll { $0.id == profile.id }
        persist()
    }

    private func update(_ profile: AvoidanceProfile, change: (inout AvoidanceProfile) -> Void) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        change(&profiles[index])
        persist()
    }

    private func persist() {
        StorageService.shared.saveAvoidanceProfiles(profiles)
    }
}
