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
    @State private var menuBarController: MenuBarController?
    
    init() {
        // Initialize OSD coordinator on app launch
        let monitor = AudioMonitor()
        _audioMonitor = State(initialValue: monitor)
        _osdCoordinator = State(initialValue: OSDCoordinator(audioMonitor: monitor))
        
        // Initialize menu bar
        _menuBarController = State(initialValue: MenuBarController(onQuit: {
            NSApplication.shared.terminate(nil)
        }))
    }
    
    var body: some Scene {
        // Empty window group - app runs as pure background agent
        Settings {
            EmptyView()
        }
    }
}
