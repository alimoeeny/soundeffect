//
//  OSDCoordinator.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import SwiftUI
import AppKit

@Observable
class OSDCoordinator {
    var isVisible = false
    private var windowController: OSDWindowController?
    private let audioMonitor: AudioMonitor
    
    init(audioMonitor: AudioMonitor) {
        self.audioMonitor = audioMonitor
        setupWindow()
        observeAudioChanges()
    }
    
    private func setupWindow() {
        let hostingView = NSHostingView(
            rootView: OSDView(
                volume: audioMonitor.volume,
                isMuted: audioMonitor.isMuted,
                isVisible: isVisible
            )
            .environment(self)
        )
        
        windowController = OSDWindowController(contentView: hostingView)
    }
    
    private func observeAudioChanges() {
        // Use withObservationTracking to monitor audio changes
        withObservationTracking {
            _ = audioMonitor.volume
            _ = audioMonitor.isMuted
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.handleAudioChange()
                self.observeAudioChanges()
            }
        }
    }
    
    private func handleAudioChange() {
        updateOSDContent()
        showOSD()
    }
    
    func showOSD() {
        isVisible = true
        updateOSDContent()
        
        if windowController?.window?.isVisible == true {
            windowController?.resetTimer()
        } else {
            windowController?.show()
        }
        
        // Hide after delay
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run {
                self.isVisible = false
                Task {
                    try? await Task.sleep(for: .seconds(0.25))
                    await MainActor.run {
                        self.windowController?.hide()
                    }
                }
            }
        }
    }
    
    private func updateOSDContent() {
        let hostingView = NSHostingView(
            rootView: OSDView(
                volume: audioMonitor.volume,
                isMuted: audioMonitor.isMuted,
                isVisible: isVisible
            )
        )
        
        windowController?.window?.contentView = hostingView
    }
}
