//
//  UpdateManager.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/19/25.
//

import Foundation
import Sparkle
import os.log

class UpdateManager: NSObject, SPUUpdaterDelegate {
    private lazy var updaterController: SPUStandardUpdaterController = {
        SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
    }()
    private let logger = Logger(subsystem: "com.suprefrontal.SoundEffect", category: "UpdateManager")

    override init() {
        super.init()
        _ = updaterController
        logger.info("UpdateManager initialized")
    }

    deinit {
        logger.info("UpdateManager deallocating")
    }

    func checkForUpdates() {
        logger.info("Checking for updates")
        updaterController.checkForUpdates(nil)
    }

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    // MARK: - SPUUpdaterDelegate

    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        logger.info("Successfully loaded appcast")
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        logger.info("Found valid update: \(item.displayVersionString)")
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        logger.error("Update check failed: \(error.localizedDescription)")
    }

    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        logger.error("Failed to download update: \(error.localizedDescription)")
    }
}
