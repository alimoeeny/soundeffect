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
    @State private var launchAtLoginManager = LaunchAtLoginManager()
    private let updateManager = UpdateManager()

    init() {
        // Initialize OSD coordinator on app launch
        let monitor = AudioMonitor()
        _audioMonitor = State(initialValue: monitor)
        _osdCoordinator = State(initialValue: OSDCoordinator(audioMonitor: monitor))

        // Initialize launch at login manager
        let loginManager = LaunchAtLoginManager()
        _launchAtLoginManager = State(initialValue: loginManager)

        // Initialize menu bar with shared update manager
        _menuBarController = State(initialValue: MenuBarController(
            onQuit: { NSApplication.shared.terminate(nil) },
            updateManager: updateManager,
            launchAtLoginManager: loginManager
        ))

        // Initialize Crash Reporter
        CrashReporter.shared.configure()
    }

    var body: some Scene {
        // Empty window group - app runs as pure background agent
        Settings {
            EmptyView()
        }
    }
}
