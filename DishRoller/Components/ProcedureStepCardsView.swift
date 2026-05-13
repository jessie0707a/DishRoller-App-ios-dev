//
//  ProcedureStepCardsView.swift
//  DishRoller
//
//  Created by Codex on 13/5/2026.
//

import SwiftUI

struct ProcedureStepCardsView: View {
    let steps: [RecipeProcedureStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                ProcedureStepCard(stepNumber: index + 1, step: step)
            }
        }
    }
}

private struct ProcedureStepCard: View {
    let stepNumber: Int
    let step: RecipeProcedureStep

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step.emoji)
                .font(.system(size: 28))
                .frame(width: 42, height: 42)
                .background(Color.yellow.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text("Step \(stepNumber)")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.gray)

                Text(step.instruction)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    ProcedureStepCardsView(
        steps: [
            RecipeProcedureStep(emoji: "🔪", instruction: "Slice the vegetables and keep each ingredient within reach."),
            RecipeProcedureStep(emoji: "🔥", instruction: "Sear everything over medium-high heat until fragrant."),
            RecipeProcedureStep(emoji: "🍽️", instruction: "Plate while warm and finish with the remaining sauce.")
        ]
    )
    .padding()
    .background(Color.yellow)
}
