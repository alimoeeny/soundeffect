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
    
    private let barCount = 16
    private let barWidth: CGFloat = 6
    private let barSpacing: CGFloat = 4
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        ZStack {
            // Background blur effect
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 20) {
                // Icon
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(isMuted ? .red : .white)
                    .symbolEffect(.bounce, value: isMuted)
                
                // Volume bars
                HStack(spacing: barSpacing) {
                    ForEach(0..<barCount, id: \.self) { index in
                        VolumeBar(
                            index: index,
                            totalBars: barCount,
                            volume: volume,
                            isMuted: isMuted,
                            barWidth: barWidth
                        )
                    }
                }
                .frame(height: 80)
            }
            .padding(30)
        }
        .frame(width: 280, height: 200)
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
    
    private var isActive: Bool {
        let threshold = Float(index) / Float(totalBars)
        return volume >= threshold && !isMuted
    }
    
    private var barColor: Color {
        if isMuted {
            return .gray.opacity(0.3)
        }
        
        let ratio = Float(index) / Float(totalBars)
        if ratio < 0.6 {
            return .white
        } else if ratio < 0.85 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: barWidth / 2)
            .fill(isActive ? barColor : Color.white.opacity(0.2))
            .frame(width: barWidth)
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
