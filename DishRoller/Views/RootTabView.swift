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
                ZStack(alignment: .bottom) {
                    selectedTabView
                    if !isRecipeOverlayPresented {
                        bottomNavigationOverlay
                    }
                }
                .ignoresSafeArea(.keyboard)
                .transition(.opacity)
                .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isRecipeOverlayPresented)
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

    @ViewBuilder
    private var selectedTabView: some View {
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

    private var isRecipeOverlayPresented: Bool {
        appVM.selectedTab == 2
            && (
                appVM.currentRecipe != nil
                    || appVM.isRecipeHistoryPresented
                    || appVM.isFavouriteListPresented
            )
    }

    private var bottomNavigationOverlay: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.55), location: 0.48),
                            .init(color: .black, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 130)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)

            BottomTabBar(selectedTab: $appVM.selectedTab)
        }
    }
}
