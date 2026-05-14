//
//  BottomTabBar.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            tabButton(index: 0, title: "Storage", icon: "shippingbox")
            tabButton(index: 1, title: "DishRoll", icon: "record.circle")
            tabButton(index: 2, title: "Menu", icon: "book")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 99)
                .fill(Color.black)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, -6)
    }

    private func tabButton(index: Int, title: String, icon: String) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(selectedTab == index ? Color.black : Color.yellow)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(selectedTab == index ? Color.black : Color.yellow)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selectedTab == index ? Color.yellow : Color.clear)
            .clipShape(Capsule())
        }
    }
}
