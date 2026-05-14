//
//  CongratulationsView.swift
//  DishRoller
//

import SwiftUI

struct CongratulationsView: View {
    let recipeName: String
    @EnvironmentObject var appVM: AppViewModel

    @State private var bounce = false
    @State private var floatA = false
    @State private var floatB = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                celebrationSection

                Spacer().frame(height: 36)

                recipeNameCard

                Spacer().frame(height: 16)

                Text("Your ingredients have been updated in storage.")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.systemGray))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                rollAgainButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                bounce = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                floatA = true
            }
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                floatB = true
            }
        }
    }

    private var celebrationSection: some View {
        VStack(spacing: 24) {
            ZStack {
                Text("🎉")
                    .font(.system(size: 44))
                    .offset(x: -90, y: floatA ? -18 : 10)

                Text("✨")
                    .font(.system(size: 32))
                    .offset(x: 95, y: floatB ? -12 : 16)

                Text("🎊")
                    .font(.system(size: 36))
                    .offset(x: -60, y: floatB ? 28 : -8)

                Text("⭐️")
                    .font(.system(size: 28))
                    .offset(x: 70, y: floatA ? 22 : -10)

                Text("🏆")
                    .font(.system(size: 96))
                    .scaleEffect(bounce ? 1.08 : 0.93)
            }
            .frame(height: 180)

            VStack(spacing: 8) {
                Text("Congratulations!")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.yellow)

                Text("You cooked it!")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
        }
    }

    private var recipeNameCard: some View {
        VStack(spacing: 6) {
            Text("Today's dish")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color(.systemGray))

            Text(recipeName)
                .font(.title3)
                .fontWeight(.black)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity)
        .background(Color.yellow)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 32)
    }

    private var rollAgainButton: some View {
        Button {
            appVM.selectedTab = 1
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.headline.weight(.black))
                Text("Roll Again!")
                    .font(.headline)
                    .fontWeight(.black)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.yellow)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    let appVM = AppViewModel.previewSample
    CongratulationsView(recipeName: "Black Pepper Garlic Chicken")
        .environmentObject(appVM)
}
