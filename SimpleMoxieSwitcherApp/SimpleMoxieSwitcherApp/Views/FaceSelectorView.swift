//
//  FaceSelectorView.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct FaceSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var controller: PersonalityController

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("😊 Choose Moxie's Face")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 15) {
                    ForEach(MoxieEmotion.allCases, id: \.rawValue) { emotion in
                        Button(action: {
                            Task {
                                await controller.setFace(emotion)
                            }
                        }) {
                            VStack(spacing: 10) {
                                Text(emotion.emoji)
                                    .font(.system(size: 60))
                                Text(emotion.displayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                            }
                            .foregroundColor(.white)
                            .frame(width: 120, height: 100)
                            .background(
                                ZStack {
                                    // Base plastic color - vibrant colors for each emotion
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            emotion.color.opacity(0.9),
                                            emotion.color.opacity(0.7)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )

                                    // Glossy highlight at top (plastic shine effect)
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.6),
                                            Color.white.opacity(0.0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                }
                            )
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                    .blur(radius: 1)
                            )
                            .shadow(color: emotion.color.opacity(0.6), radius: 15, x: 0, y: 8)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}
