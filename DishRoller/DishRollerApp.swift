//
//  DishRollerApp.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

@main
struct DishRollerApp: App {
    @StateObject private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appVM)
        }
    }
}
