//
//  IngredientCardViews.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI

struct IngredientCardView: View {
    let ingredient: Ingredient
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)

            GroceryCategoryLineArt(category: ingredient.category)
                .frame(width: 128, height: 92)
                .padding(.top, 18)
                .allowsHitTesting(false)

            VStack(spacing: 8) {
                Text(ingredient.category.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Text(ingredient.name)
                    .font(.headline)
                    .fontWeight(.black)
                    .lineLimit(1)

                HStack {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill")
                    }

                    Spacer()

                    Text("\(formatAmount(ingredient.amount)) \(ingredient.unit.rawValue)")
                        .fontWeight(.bold)

                    Spacer()

                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.yellow)
            }
            .padding(.top, 8)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    }
}

private struct GroceryCategoryLineArt: View {
    let category: IngredientCategory

    var body: some View {
        Canvas { context, size in
            let strokeStyle = StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            let thinStrokeStyle = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            let color = Color.black.opacity(0.12)

            switch category {
            case .meat:
                stroke(meatSteak(in: size), in: &context, color: color, style: strokeStyle)
                stroke(meatBone(in: size), in: &context, color: color, style: thinStrokeStyle)
                stroke(meatChunk(in: size), in: &context, color: color, style: strokeStyle)
            case .veg:
                stroke(carrot(in: size), in: &context, color: color, style: strokeStyle)
                stroke(carrotLeaves(in: size), in: &context, color: color, style: thinStrokeStyle)
                stroke(leafyGreen(in: size), in: &context, color: color, style: strokeStyle)
                stroke(roundVegetable(in: size), in: &context, color: color, style: thinStrokeStyle)
            case .seafood:
                stroke(fish(in: size), in: &context, color: color, style: strokeStyle)
                stroke(fishDetails(in: size), in: &context, color: color, style: thinStrokeStyle)
                stroke(shrimp(in: size), in: &context, color: color, style: strokeStyle)
            case .drink:
                stroke(bottle(in: size), in: &context, color: color, style: strokeStyle)
                stroke(bottleLabel(in: size), in: &context, color: color, style: thinStrokeStyle)
            case .condiment:
                stroke(condimentJar(in: size), in: &context, color: color, style: strokeStyle)
                stroke(condimentCap(in: size), in: &context, color: color, style: thinStrokeStyle)
                stroke(condimentBottle(in: size), in: &context, color: color, style: strokeStyle)
            }
        }
    }

    private func stroke(_ path: Path, in context: inout GraphicsContext, color: Color, style: StrokeStyle) {
        context.stroke(path, with: .color(color), style: style)
    }

    private func meatSteak(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.18, 0.50, in: size))
        path.addCurve(
            to: point(0.53, 0.26, in: size),
            control1: point(0.20, 0.25, in: size),
            control2: point(0.42, 0.18, in: size)
        )
        path.addCurve(
            to: point(0.78, 0.53, in: size),
            control1: point(0.68, 0.30, in: size),
            control2: point(0.84, 0.38, in: size)
        )
        path.addCurve(
            to: point(0.53, 0.78, in: size),
            control1: point(0.74, 0.70, in: size),
            control2: point(0.64, 0.82, in: size)
        )
        path.addCurve(
            to: point(0.18, 0.50, in: size),
            control1: point(0.34, 0.78, in: size),
            control2: point(0.14, 0.68, in: size)
        )
        return path
    }

    private func meatBone(in size: CGSize) -> Path {
        var path = Path()
        path.addEllipse(in: rect(x: 0.45, y: 0.43, width: 0.12, height: 0.12, in: size))
        path.move(to: point(0.30, 0.58, in: size))
        path.addQuadCurve(to: point(0.62, 0.62, in: size), control: point(0.45, 0.70, in: size))
        return path
    }

    private func meatChunk(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.70, 0.18, in: size))
        path.addLine(to: point(0.88, 0.24, in: size))
        path.addLine(to: point(0.84, 0.40, in: size))
        path.addLine(to: point(0.66, 0.35, in: size))
        path.closeSubpath()
        return path
    }

    private func carrot(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.22, 0.30, in: size))
        path.addLine(to: point(0.50, 0.80, in: size))
        path.addLine(to: point(0.36, 0.24, in: size))
        path.closeSubpath()
        path.move(to: point(0.29, 0.42, in: size))
        path.addLine(to: point(0.40, 0.40, in: size))
        path.move(to: point(0.35, 0.55, in: size))
        path.addLine(to: point(0.45, 0.52, in: size))
        return path
    }

    private func carrotLeaves(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.29, 0.25, in: size))
        path.addQuadCurve(to: point(0.22, 0.08, in: size), control: point(0.20, 0.17, in: size))
        path.move(to: point(0.29, 0.25, in: size))
        path.addQuadCurve(to: point(0.34, 0.06, in: size), control: point(0.39, 0.16, in: size))
        path.move(to: point(0.29, 0.25, in: size))
        path.addQuadCurve(to: point(0.45, 0.14, in: size), control: point(0.39, 0.24, in: size))
        return path
    }

    private func leafyGreen(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.62, 0.33, in: size))
        path.addQuadCurve(to: point(0.80, 0.18, in: size), control: point(0.74, 0.18, in: size))
        path.addQuadCurve(to: point(0.75, 0.48, in: size), control: point(0.92, 0.37, in: size))
        path.addQuadCurve(to: point(0.62, 0.33, in: size), control: point(0.66, 0.47, in: size))
        path.move(to: point(0.62, 0.33, in: size))
        path.addQuadCurve(to: point(0.77, 0.30, in: size), control: point(0.70, 0.32, in: size))
        return path
    }

    private func roundVegetable(in size: CGSize) -> Path {
        var path = Path()
        path.addEllipse(in: rect(x: 0.58, y: 0.56, width: 0.18, height: 0.18, in: size))
        path.move(to: point(0.67, 0.56, in: size))
        path.addQuadCurve(to: point(0.74, 0.47, in: size), control: point(0.72, 0.50, in: size))
        return path
    }

    private func fish(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.16, 0.44, in: size))
        path.addQuadCurve(to: point(0.62, 0.32, in: size), control: point(0.36, 0.20, in: size))
        path.addQuadCurve(to: point(0.82, 0.46, in: size), control: point(0.73, 0.35, in: size))
        path.addLine(to: point(0.96, 0.34, in: size))
        path.addLine(to: point(0.94, 0.58, in: size))
        path.addLine(to: point(0.82, 0.46, in: size))
        path.addQuadCurve(to: point(0.16, 0.44, in: size), control: point(0.52, 0.70, in: size))
        return path
    }

    private func fishDetails(in size: CGSize) -> Path {
        var path = Path()
        path.addEllipse(in: rect(x: 0.29, y: 0.39, width: 0.03, height: 0.03, in: size))
        path.move(to: point(0.58, 0.35, in: size))
        path.addQuadCurve(to: point(0.58, 0.58, in: size), control: point(0.51, 0.47, in: size))
        return path
    }

    private func shrimp(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.32, 0.78, in: size))
        path.addCurve(
            to: point(0.68, 0.70, in: size),
            control1: point(0.40, 0.56, in: size),
            control2: point(0.65, 0.55, in: size)
        )
        path.addCurve(
            to: point(0.50, 0.84, in: size),
            control1: point(0.70, 0.88, in: size),
            control2: point(0.50, 0.93, in: size)
        )
        path.move(to: point(0.40, 0.68, in: size))
        path.addLine(to: point(0.34, 0.58, in: size))
        path.move(to: point(0.50, 0.64, in: size))
        path.addLine(to: point(0.48, 0.52, in: size))
        path.move(to: point(0.62, 0.66, in: size))
        path.addLine(to: point(0.68, 0.56, in: size))
        return path
    }

    private func bottle(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.43, 0.12, in: size))
        path.addLine(to: point(0.57, 0.12, in: size))
        path.addLine(to: point(0.57, 0.28, in: size))
        path.addQuadCurve(to: point(0.70, 0.42, in: size), control: point(0.66, 0.32, in: size))
        path.addLine(to: point(0.70, 0.84, in: size))
        path.addQuadCurve(to: point(0.30, 0.84, in: size), control: point(0.50, 0.92, in: size))
        path.addLine(to: point(0.30, 0.42, in: size))
        path.addQuadCurve(to: point(0.43, 0.28, in: size), control: point(0.34, 0.32, in: size))
        path.closeSubpath()
        return path
    }

    private func bottleLabel(in size: CGSize) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect(x: 0.38, y: 0.52, width: 0.24, height: 0.16, in: size), cornerSize: CGSize(width: 6, height: 6))
        path.move(to: point(0.42, 0.20, in: size))
        path.addLine(to: point(0.58, 0.20, in: size))
        return path
    }

    private func condimentJar(in size: CGSize) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect(x: 0.18, y: 0.32, width: 0.30, height: 0.48, in: size), cornerSize: CGSize(width: 10, height: 10))
        path.move(to: point(0.22, 0.48, in: size))
        path.addLine(to: point(0.44, 0.48, in: size))
        path.move(to: point(0.25, 0.58, in: size))
        path.addLine(to: point(0.41, 0.58, in: size))
        return path
    }

    private func condimentCap(in size: CGSize) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect(x: 0.22, y: 0.20, width: 0.22, height: 0.12, in: size), cornerSize: CGSize(width: 5, height: 5))
        path.move(to: point(0.26, 0.24, in: size))
        path.addLine(to: point(0.26, 0.28, in: size))
        path.move(to: point(0.33, 0.23, in: size))
        path.addLine(to: point(0.33, 0.29, in: size))
        path.move(to: point(0.40, 0.24, in: size))
        path.addLine(to: point(0.40, 0.28, in: size))
        return path
    }

    private func condimentBottle(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0.66, 0.18, in: size))
        path.addLine(to: point(0.78, 0.18, in: size))
        path.addLine(to: point(0.78, 0.30, in: size))
        path.addQuadCurve(to: point(0.86, 0.43, in: size), control: point(0.84, 0.35, in: size))
        path.addLine(to: point(0.82, 0.82, in: size))
        path.addLine(to: point(0.62, 0.82, in: size))
        path.addLine(to: point(0.58, 0.43, in: size))
        path.addQuadCurve(to: point(0.66, 0.30, in: size), control: point(0.60, 0.35, in: size))
        path.closeSubpath()
        path.move(to: point(0.63, 0.58, in: size))
        path.addLine(to: point(0.83, 0.58, in: size))
        return path
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }

    private func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, in size: CGSize) -> CGRect {
        CGRect(x: x * size.width, y: y * size.height, width: width * size.width, height: height * size.height)
    }
}
