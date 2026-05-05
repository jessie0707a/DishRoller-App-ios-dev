//
//  OnlineShoppingView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct OnlineShoppingView: View {
    private let shops = [
        "Woolworths Online",
        "Coles Online",
        "Asian Grocery Online"
    ]

    var body: some View {
        List {
            ForEach(shops, id: \.self) { shop in
                HStack {
                    Image(systemName: "cart.fill")
                        .foregroundColor(.yellow)
                    Text(shop)
                        .fontWeight(.bold)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Online Shopping")
    }
}
