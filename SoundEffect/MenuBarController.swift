//
//  MenuBarController.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import AppKit
import ServiceManagement
import SwiftUI

class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let onQuit: () -> Void
    private let updateManager: UpdateManager
    private let launchAtLoginManager: LaunchAtLoginManager
    private var launchAtLoginItem: NSMenuItem?
    
    init(onQuit: @escaping () -> Void, updateManager: UpdateManager, launchAtLoginManager: LaunchAtLoginManager) {
        self.onQuit = onQuit
        self.updateManager = updateManager
        self.launchAtLoginManager = launchAtLoginManager
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
        menu.delegate = self
        
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
        
        // Launch at Login item
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        menu.addItem(launchItem)
        self.launchAtLoginItem = launchItem
        
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
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        
        let alert = NSAlert()
        alert.messageText = "SoundEffect"
        alert.informativeText = "Custom volume OSD for macOS\n\nVersion \(version) (Build \(build))\n\nMonitors system audio and displays a beautiful overlay when volume changes."
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
    
    @objc private func toggleLaunchAtLogin() {
        let newState = !launchAtLoginManager.isEnabled
        
        do {
            try launchAtLoginManager.setEnabled(newState)
        } catch {
            // Revert UI state
            launchAtLoginManager.refreshStatus()
            updateLaunchAtLoginItemState()
            
            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Launch at Login Error"
            alert.informativeText = "Failed to \(newState ? "enable" : "disable") launch at login.\n\nError: \(error.localizedDescription)\n\nYou can manage login items in System Settings > General > Login Items."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            print("[LaunchAtLogin] Error toggling launch at login: \(error)")
        }
    }
    
    // MARK: - NSMenuDelegate
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        launchAtLoginManager.refreshStatus()
        updateLaunchAtLoginItemState()
    }
    
    private func updateLaunchAtLoginItemState() {
        launchAtLoginItem?.state = launchAtLoginManager.isEnabled ? .on : .off
    }
}
