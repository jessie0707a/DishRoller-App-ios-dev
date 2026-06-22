//
//  AppEnums.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import Foundation

enum IngredientCategory: String, CaseIterable, Codable, Identifiable {
    case meat = "MEAT"
    case veg = "VEG"
    case seafood = "SEAFOOD"
    case drink = "DRINK"
    case condiment = "CONDIMENT"
    case other = "OTHER"

    var id: String { rawValue }

    var categoryIcon: String {
        switch self {
        case .meat:      "fork.knife"
        case .veg:       "leaf"
        case .seafood:   "fish"
        case .drink:     "cup.and.saucer"
        case .condiment: "flame"
        case .other:     "shippingbox"
        }
    }

    var foodIconAssetName: String {
        switch self {
        case .meat:
            "food-category-meat"
        case .veg:
            "food-category-veg"
        case .seafood:
            "food-category-seafood"
        case .drink:
            "food-category-drink"
        case .condiment:
            "food-category-condiment"
        case .other:
            "food-category-other"
        }
    }
}

enum UnitType: String, CaseIterable, Codable, Identifiable {
    case kg = "kg"
    case g = "g"
    case liter = "L"
    case ml = "ml"
    case pcs = "pcs"

    var id: String { rawValue }
}

enum CookingTime: String, CaseIterable, Identifiable {
    case fifteen = "15 min"
    case thirty = "30 min"
    case fortyFive = "45 min"
    case oneHour = "1 hr"
    case twoHours = "2 hr"
    case threeHours = "3 hr"

    var id: String { rawValue }
}

enum DishType: String, CaseIterable, Identifiable {
    case any = "Any"
    case brunch = "Brunch"
    case mainCourse = "Main Course"
    case salad = "Salad"
    case appetizer = "Appetizer"
    case soup = "Soup"
    case dessert = "Dessert"

    var id: String { rawValue }
}

enum FlavourStyle: String, CaseIterable, Identifiable {
    case any = "Any"
    case chinese = "Chinese"
    case japanese = "Japanese"
    case indian = "Indian"
    case thai = "Thai"
    case middleEastern = "Middle Eastern"
    case european = "European"
    case mediterranean = "Mediterranean"

    var id: String { rawValue }
}
