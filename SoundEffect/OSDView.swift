//
//  OSDView.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import SwiftUI

struct OSDView: View {
    let volume: Float
    let isMuted: Bool
    let isVisible: Bool

    private let barCount = 12
    private let barWidth: CGFloat = 15
    private let barHeight: CGFloat = 15
    private let barSpacing: CGFloat = 6
    private let cornerRadius: CGFloat = 32

    var body: some View {
        ZStack {
            // Background blur effect with border
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(red: 235/255, green: 233/255, blue: 227/255).opacity(0.46))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )

            VStack(spacing: 20) {
                // Icon
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(isMuted ? .red : Color(red: 119/255, green: 117/255, blue: 113/255))
                    .symbolEffect(.bounce, value: isMuted)

                // Volume bars
                HStack(spacing: barSpacing) {
                    ForEach(0..<barCount, id: \.self) { index in
                        VolumeBar(
                            index: index,
                            totalBars: barCount,
                            volume: volume,
                            isMuted: isMuted,
                            barWidth: barWidth,
                            barHeight: barHeight
                        )
                    }
                }
                .frame(height: 50)
            }
            .padding(30)
        }
        .frame(width: 280, height: 200)
        .padding(15)
        .compositingGroup()
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.85)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isVisible)
        .animation(.easeInOut(duration: 0.15), value: volume)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMuted)
    }
}

struct VolumeBar: View {
    let index: Int
    let totalBars: Int
    let volume: Float
    let isMuted: Bool
    let barWidth: CGFloat
    let barHeight: CGFloat

    private var isActive: Bool {
        let threshold = Float(index) / Float(totalBars)
        return volume >= threshold && !isMuted
    }

    private var barColor: Color {
        if isMuted {
            return .gray.opacity(0.3)
        }

        let ratio = Float(index) / Float(totalBars)
        let baseColor = Color(red: 119/255, green: 117/255, blue: 113/255)
        
        if ratio < 0.6 {
            return baseColor
        } else if ratio < 0.85 {
            return .yellow
        } else {
            return .red
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(isActive ? barColor : Color(red: 119/255, green: 117/255, blue: 113/255).opacity(0.15))
            .frame(width: barWidth, height: barHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(isActive ? Color(red: 119/255, green: 117/255, blue: 113/255).opacity(0.2) : Color.clear, lineWidth: 0.5)
            )
            .shadow(color: isActive ? barColor.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
            .animation(.easeOut(duration: 0.08), value: isActive)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            OSDView(volume: 0.7, isMuted: false, isVisible: true)
            OSDView(volume: 0.3, isMuted: false, isVisible: true)
            OSDView(volume: 0.5, isMuted: true, isVisible: true)
        }
    }
}
