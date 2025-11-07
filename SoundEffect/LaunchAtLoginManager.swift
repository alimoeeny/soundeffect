import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled: Bool

    var status: SMAppService.Status { SMAppService.mainApp.status }

    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }

    func refreshStatus() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
        refreshStatus()
    }
}
