//
//  AppDelegate.swift
//  SoundEffect
//
//  Created by Cascade on 12/6/25.
//

import AppKit

extension Notification.Name {
    static let showMenuBarIcon = Notification.Name("showMenuBarIcon")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When the user re-opens the app (e.g. via Finder/Launchpad/Spotlight),
        // show the menu bar icon even if it was hidden.
        NotificationCenter.default.post(name: .showMenuBarIcon, object: nil)
        return true
    }
}
