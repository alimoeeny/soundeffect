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
    private let soundFeedback = SoundFeedback()
    private var lastVolume: Float = 0.0
    private var lastMuteState: Bool = false
    private var hideTask: Task<Void, Never>?
    
    init(audioMonitor: AudioMonitor) {
        self.audioMonitor = audioMonitor
        self.lastVolume = audioMonitor.volume
        self.lastMuteState = audioMonitor.isMuted
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
        // Play sound feedback
        if audioMonitor.isMuted != lastMuteState {
            soundFeedback.playMuteSound()
            lastMuteState = audioMonitor.isMuted
        } else if abs(audioMonitor.volume - lastVolume) > 0.01 {
            soundFeedback.playVolumeChangeSound(volume: audioMonitor.volume)
            lastVolume = audioMonitor.volume
        }
        
        updateOSDContent()
        showOSD()
    }
    
    func showOSD() {
        // Cancel any existing hide task to prevent flickering
        hideTask?.cancel()
        
        isVisible = true
        updateOSDContent()
        
        if windowController?.window?.isVisible == true {
            windowController?.resetTimer()
        } else {
            windowController?.show()
        }
        
        // Hide after delay
        hideTask = Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.isVisible = false
                Task {
                    try? await Task.sleep(for: .seconds(0.25))
                    guard !Task.isCancelled else { return }
                    
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
