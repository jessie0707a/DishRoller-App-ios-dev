//
//  CongratulationsView.swift
//  DishRoller
//

import SwiftUI

struct CongratulationsView: View {
    let recipe: Recipe
    @Binding var isPresented: Bool
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            popupCard
                .padding(.horizontal, 24)
        }
    }

    private var popupCard: some View {
        VStack(spacing: 0) {
            // Close button row
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Text("Congratulations!")
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.yellow)
                .padding(.top, 4)

            dishIcon
                .padding(.vertical, 8)

            Text("Amazing job you've done !\nIngredients will be deducted, please\nenjoy your delicious dish~")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                appVM.consumeRecipeIngredients(for: recipe)
                isPresented = false
            } label: {
                Text("Finished & Leave")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.yellow, lineWidth: 2)
        )
    }

    private var dishIcon: some View {
        ZStack {
            // Steam lines
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    SteamCurve()
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 10, height: 20)
                }
            }
            .offset(y: -48)

            // Dome knob
            Circle()
                .stroke(Color.yellow, lineWidth: 2)
                .frame(width: 8, height: 8)
                .offset(y: -30)

            // Dome
            DomePath()
                .stroke(Color.yellow, lineWidth: 2.5)
                .frame(width: 76, height: 38)
                .offset(y: -10)

            // Tray base
            Capsule()
                .stroke(Color.yellow, lineWidth: 2.5)
                .frame(width: 96, height: 7)
                .offset(y: 10)

            // Hand
            Image(systemName: "hand.raised")
                .font(.system(size: 44, weight: .thin))
                .foregroundColor(.yellow)
                .offset(y: 40)
        }
        .frame(height: 130)
    }
}

private struct SteamCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY * 0.65),
            control2: CGPoint(x: rect.minX, y: rect.maxY * 0.35)
        )
        return path
    }
}

private struct DomePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.15, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.85, y: rect.minY)
        )
        return path
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        let appVM = AppViewModel.previewSample
        if let recipe = appVM.currentRecipe {
            CongratulationsView(recipe: recipe, isPresented: .constant(true))
                .environmentObject(appVM)
        }
    }
}
