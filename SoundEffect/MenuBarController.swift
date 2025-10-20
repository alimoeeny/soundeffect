//
//  MenuBarController.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import AppKit
import SwiftUI

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let onQuit: () -> Void
    private let updateManager: UpdateManager
    
    init(onQuit: @escaping () -> Void, updateManager: UpdateManager) {
        self.onQuit = onQuit
        self.updateManager = updateManager
        super.init()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true  // Adapts to light/dark mode
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // About item
        let aboutItem = NSMenuItem(
            title: "About SoundEffect",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings item (placeholder for future)
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Check for Updates item
        let updateItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(
            title: "Quit SoundEffect",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "SoundEffect"
        alert.informativeText = "Custom volume OSD for macOS\n\nVersion 1.0\n\nMonitors system audio and displays a beautiful overlay when volume changes."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func showSettings() {
        let alert = NSAlert()
        alert.messageText = "Settings"
        alert.informativeText = "Settings panel coming soon!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func checkForUpdates() {
        updateManager.checkForUpdates()
    }
    
    @objc private func quitApp() {
        onQuit()
    }
}
