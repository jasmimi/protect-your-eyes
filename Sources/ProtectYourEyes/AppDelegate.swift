import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var manager: EyeProtectionManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupNotificationPermissions()
        setupMenuBar()

        manager = EyeProtectionManager()
        manager?.onTimeUpdate = { [weak self] timeString in
            self?.updateStatusLabel(timeString)
        }
        manager?.start()
    }

    // MARK: - Notification permissions

    private func setupNotificationPermissions() {
        // Register the "OK" action that the user taps to acknowledge the alert
        let okAction = UNNotificationAction(
            identifier: NotificationID.okAction,
            title: "OK, I'll look around! 👀",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: NotificationID.category,
            actions: [okAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("[ProtectYourEyes] Notification permission error: \(error.localizedDescription)")
            }
            if !granted {
                print("[ProtectYourEyes] Notification permission not granted – alerts will be silent.")
            }
        }
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Protect Your Eyes")
            button.toolTip = "Protect Your Eyes"
        }

        let menu = NSMenu()

        // Dynamic status row (tag 1 is used to find it for updates)
        let statusMenuItem = NSMenuItem(title: "Active: 00:00 / 10:00", action: nil, keyEquivalent: "")
        statusMenuItem.tag = MenuTag.statusRow
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(.separator())

        let resetItem = NSMenuItem(
            title: "Reset Timer",
            action: #selector(resetTimerAction),
            keyEquivalent: "r"
        )
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(.separator())

        menu.addItem(
            NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        )

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func resetTimerAction() {
        manager?.resetTimer()
    }

    // MARK: - Updates

    func updateStatusLabel(_ timeString: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.menu?.item(withTag: MenuTag.statusRow)?.title =
                "Active: \(timeString) / 10:00"
        }
    }
}

// MARK: - Constants

enum NotificationID {
    static let request  = "protect-your-eyes"
    static let category = "EYE_PROTECTION"
    static let okAction = "OK_ACTION"
}

enum MenuTag {
    static let statusRow = 1
}
