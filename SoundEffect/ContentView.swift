//
//  ContentView.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import SwiftUI

struct ContentView: View {
    @State private var audioMonitor = AudioMonitor()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Monitor Test")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Volume:")
                        .fontWeight(.semibold)
                    Text("\(Int(audioMonitor.volume * 100))%")
                }
                
                HStack {
                    Text("Muted:")
                        .fontWeight(.semibold)
                    Text(audioMonitor.isMuted ? "Yes" : "No")
                }
                
                HStack {
                    Text("Device:")
                        .fontWeight(.semibold)
                    Text(audioMonitor.outputDeviceName)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("Press volume keys to test")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
}

#Preview {
    ContentView()
}
