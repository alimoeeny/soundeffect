//
//  OSDWindowController.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import SwiftUI
import AppKit

class OSDWindowController: NSWindowController {
    private var hideTimer: Timer?
    private let displayDuration: TimeInterval = 1.8
    
    convenience init(contentView: NSView) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 310, height: 310),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Window configuration
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isMovableByWindowBackground = false
        window.hasShadow = true
        window.contentView = contentView
        
        // Ensure proper rendering with layer-backed view
        contentView.wantsLayer = true
        contentView.layer?.masksToBounds = false
        
        // Add shadow to the layer for clean rendering
        contentView.layer?.shadowColor = NSColor.black.cgColor
        contentView.layer?.shadowOpacity = 0.4
        contentView.layer?.shadowRadius = 25
        contentView.layer?.shadowOffset = CGSize(width: 0, height: -12)
        
        self.init(window: window)
        
        // Center window on screen
        centerWindow()
    }
    
    func show() {
        guard let window = window else { return }
        
        // Cancel any existing hide timer
        hideTimer?.invalidate()
        
        // Show window
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        
        // Set up auto-hide timer
        hideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
    
    func hide() {
        hideTimer?.invalidate()
        window?.orderOut(nil)
    }
    
    func resetTimer() {
        // If window is visible, reset the hide timer
        if window?.isVisible == true {
            hideTimer?.invalidate()
            hideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
                self?.hide()
            }
        }
    }
    
    private func centerWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowFrame = window.frame
        
        let x = screenFrame.midX - windowFrame.width / 2
        // Position at 1/4 from bottom (3/4 from top)
        let y = screenFrame.minY + (screenFrame.height * 0.25) - windowFrame.height / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
