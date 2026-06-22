//
//  SplashView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isPresented = false

    private let wheelFrames = (1...6).map { "dishroller-wheel-\($0)" }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.yellow.opacity(0.11),
                    Color.yellow.opacity(0.025),
                    Color.clear
                ],
                center: .center,
                startRadius: 18,
                endRadius: 230
            )
            .frame(width: 430, height: 430)
            .offset(y: 4)
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Text("DishRoller")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(Color.yellow)
                    .tracking(-1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24)
                    .offset(y: isPresented ? 0 : -14)
                    .opacity(isPresented ? 1 : 0)

                Text("YOUR NEXT MEAL, ONE SPIN AWAY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .tracking(1.7)
                    .padding(.top, 8)
                    .opacity(isPresented ? 1 : 0)

                rollingWheel
                    .frame(width: 230, height: 230)
                    .shadow(color: Color.yellow.opacity(0.2), radius: 22)
                    .padding(.top, 24)
                    .scaleEffect(isPresented ? 1 : 0.88)
                    .opacity(isPresented ? 1 : 0)

                Capsule()
                    .fill(Color.yellow)
                    .frame(width: 42, height: 4)
                    .padding(.top, 24)
                    .scaleEffect(x: isPresented ? 1 : 0.15)

                Text("Spin it. Cook it. Love it.")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.yellow)
                    .multilineTextAlignment(.center)
                    .padding(.top, 18)
                    .opacity(isPresented ? 1 : 0)
                    .offset(y: isPresented ? 0 : 10)
            }
            .padding(.horizontal, 24)
            .offset(y: -8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
                isPresented = true
            }
        }
    }

    private var rollingWheel: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: reduceMotion)) { context in
            let frameIndex = reduceMotion
                ? 0
                : Int(context.date.timeIntervalSinceReferenceDate / 0.12) % wheelFrames.count

            Image(wheelFrames[frameIndex])
                .resizable()
                .scaledToFit()
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    SplashView()
        .environmentObject(AppViewModel())
}
