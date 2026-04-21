import AppKit
import UserNotifications

/// Tracks consecutive screen-active seconds, fires a `UNUserNotification` at 10 minutes,
/// and resets when the user acknowledges the alert or the screen goes to sleep / locks.
final class EyeProtectionManager: NSObject {

    /// Called on the main thread each second with a "MM:SS" string, e.g. "03:42".
    var onTimeUpdate: ((String) -> Void)?

    // MARK: - Private state

    private var timer: Timer?
    private var activeSeconds: Int = 0
    private var waitingForAcknowledgement: Bool = false
    private let targetSeconds = 600   // 10 minutes

    // MARK: - Public interface

    func start() {
        UNUserNotificationCenter.current().delegate = self
        registerSystemObservers()
        startCounting()
    }

    /// Resets the elapsed counter to zero and restarts the countdown.
    /// Called automatically when the screen sleeps/locks or the notification is acknowledged.
    func resetTimer() {
        dispatchPrecondition(condition: .onQueue(.main))
        activeSeconds = 0
        waitingForAcknowledgement = false
        stopCounting()
        startCounting()
        onTimeUpdate?("00:00")
    }

    // MARK: - Timer

    private func startCounting() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopCounting() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !waitingForAcknowledgement else { return }

        activeSeconds += 1

        let minutes = activeSeconds / 60
        let seconds = activeSeconds % 60
        onTimeUpdate?(String(format: "%02d:%02d", minutes, seconds))

        if activeSeconds >= targetSeconds {
            sendEyeProtectionNotification()
        }
    }

    // MARK: - System observers

    private func registerSystemObservers() {
        let workspaceNC = NSWorkspace.shared.notificationCenter

        // Display turns off (sleep / energy saver)
        workspaceNC.addObserver(
            self,
            selector: #selector(handleScreenOff),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )

        // Screen lock ("Lock Screen" menu item or auto-lock after inactivity)
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleScreenOff),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
    }

    @objc private func handleScreenOff(_ note: Notification) {
        DispatchQueue.main.async { [weak self] in
            // Remove any pending eye-protection notification so it doesn't appear on wake
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [NotificationID.request]
            )
            UNUserNotificationCenter.current().removeDeliveredNotifications(
                withIdentifiers: [NotificationID.request]
            )
            self?.resetTimer()
        }
    }

    // MARK: - Notification

    private func sendEyeProtectionNotification() {
        // Pause the countdown; it resumes after the user acknowledges
        waitingForAcknowledgement = true

        let content = UNMutableNotificationContent()
        content.title = "Protect Your Eyes! 👀"
        content.body  = "I've been active for 10 minutes. Please look around and protect your eyes!"
        content.sound = .default
        content.categoryIdentifier = NotificationID.category

        // Replace any previously delivered (unacknowledged) alert
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [NotificationID.request]
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [NotificationID.request]
        )

        let request = UNNotificationRequest(
            identifier: NotificationID.request,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[ProtectYourEyes] Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension EyeProtectionManager: UNUserNotificationCenterDelegate {

    /// Called when the user interacts with the notification (taps it or chooses an action).
    /// Any interaction is treated as acknowledgement and resets the timer.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.resetTimer()
        }
        completionHandler()
    }

    /// Allow the banner to appear even while the app is active (it lives in the menu bar).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
