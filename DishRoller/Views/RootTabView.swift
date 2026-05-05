//
//  RootTabView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        switch appVM.selectedTab {
                        case 0:
                            StorageView()
                        case 1:
                            DishRollerView()
                        case 2:
                            MenuView()
                        default:
                            StorageView()
                        }
                    }

                    BottomTabBar(selectedTab: $appVM.selectedTab)
                }
                .ignoresSafeArea(.keyboard)
                .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}
