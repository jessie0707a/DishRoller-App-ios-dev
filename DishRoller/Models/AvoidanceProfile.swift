//
//  AvoidanceProfile.swift
//  DishRoller
//

import Foundation

struct AvoidanceProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var personName: String
    var avoidFoods: String
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        personName: String = "",
        avoidFoods: String = "",
        isSelected: Bool = false
    ) {
        self.id = id
        self.personName = personName
        self.avoidFoods = avoidFoods
        self.isSelected = isSelected
    }
}
