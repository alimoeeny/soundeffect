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
    private let hideMenuBarIconKey = "hideMenuBarIcon"

    init(onQuit: @escaping () -> Void, updateManager: UpdateManager, launchAtLoginManager: LaunchAtLoginManager) {
        self.onQuit = onQuit
        self.updateManager = updateManager
        self.launchAtLoginManager = launchAtLoginManager
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(forceShowMenuBarIcon), name: .showMenuBarIcon, object: nil)

        setupMenuBar()
    }

    private func setupMenuBar() {
        if UserDefaults.standard.bool(forKey: hideMenuBarIconKey) {
            return
        }

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

        // Share Crash Reports item
        let crashReportItem = NSMenuItem(
            title: "Share Crash Reports",
            action: #selector(toggleCrashReporting),
            keyEquivalent: ""
        )
        crashReportItem.target = self
        crashReportItem.state = CrashReporter.shared.isEnabled ? .on : .off
        menu.addItem(crashReportItem)

        menu.addItem(NSMenuItem.separator())

        // Hide Menu Bar Icon item
        let hideItem = NSMenuItem(
            title: "Hide Menu Bar Icon",
            action: #selector(confirmHideMenuBarIcon),
            keyEquivalent: ""
        )
        hideItem.target = self
        menu.addItem(hideItem)

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

    @objc private func confirmHideMenuBarIcon() {
        let alert = NSAlert()
        alert.messageText = "Hide Menu Bar Icon?"
        alert.informativeText = "The menu bar icon will be hidden. To show it again, simply open SoundEffect from your Applications folder or Spotlight."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Hide")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            toggleHideMenuBarIcon()
        }
    }

    @objc private func forceShowMenuBarIcon() {
        UserDefaults.standard.set(false, forKey: hideMenuBarIconKey)
        if statusItem == nil {
            setupMenuBar()
        }
    }

    private func toggleHideMenuBarIcon() {
        let shouldHide = true // We only call this when hiding
        UserDefaults.standard.set(shouldHide, forKey: hideMenuBarIconKey)
        statusItem = nil
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

    @objc private func toggleCrashReporting(_ sender: NSMenuItem) {
        let newState = !CrashReporter.shared.isEnabled
        CrashReporter.shared.isEnabled = newState
        sender.state = newState ? .on : .off

        if newState {
            let alert = NSAlert()
            alert.messageText = "Crash Reporting Enabled"
            alert.informativeText = "Thank you for helping improve SoundEffect! Crash reports will be sent anonymously."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
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
