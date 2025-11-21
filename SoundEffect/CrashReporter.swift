//
//  CrashReporter.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 11/20/25.
//

import Foundation
import Sentry

@Observable
class CrashReporter {
    static let shared = CrashReporter()

    private let kShareCrashReportsKey = "ShareCrashReports"

    // TODO: Replace with your actual Sentry DSN
    private let sentryDSN = "https://dfafea3188a29745e8bdc8785dcebb8d@o4510400150896640.ingest.us.sentry.io/4510400153976832"

    var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: kShareCrashReportsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kShareCrashReportsKey)
            if newValue {
                startSentry()
            } else {
                // Sentry SDK doesn't support stopping once started in the same session easily,
                // but we can close the client to stop sending new events.
                SentrySDK.close()
            }
        }
    }

    private init() {}

    func configure() {
        if isEnabled {
            startSentry()
        }
    }

    private func startSentry() {
        guard !sentryDSN.contains("YOUR_SENTRY_DSN_HERE") else {
            print("[CrashReporter] Sentry DSN not set. Skipping initialization.")
            return
        }

        SentrySDK.start { options in
            options.dsn = self.sentryDSN
            options.debug = true // Helpful for debugging integration

            // Privacy: Don't send PII
            options.sendDefaultPii = false

            // Enable performance monitoring
            options.tracesSampleRate = 1.0
        }
    }
}
