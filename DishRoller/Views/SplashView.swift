//
//  SplashView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct SplashView: View {
    @State private var bounce = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image("dishroller-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .offset(y: bounce ? -18 : 18)
                    .animation(
                        .easeInOut(duration: 0.75)
                        .repeatForever(autoreverses: true),
                        value: bounce
                    )

                Text("Spin it. Cook it. Love it.")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundColor(.yellow)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .onAppear {
            bounce = true
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AppViewModel())
}
