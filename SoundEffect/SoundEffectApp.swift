//
//  SoundEffectApp.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import SwiftUI

@main
struct SoundEffectApp: App {
    @State private var audioMonitor = AudioMonitor()
    @State private var osdCoordinator: OSDCoordinator?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if osdCoordinator == nil {
                        osdCoordinator = OSDCoordinator(audioMonitor: audioMonitor)
                    }
                }
        }
    }
}
