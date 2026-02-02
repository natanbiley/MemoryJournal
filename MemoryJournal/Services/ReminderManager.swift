import Foundation
import UserNotifications

@Observable
class ReminderManager {
    static let shared = ReminderManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderIdentifier = "daily-journal-reminder"

    // UserDefaults keys
    private let hasSeenOnboardingKey = "hasSeenReminderOnboarding"
    private let remindersEnabledKey = "remindersEnabled"
    private let reminderHourKey = "reminderHour"
    private let reminderMinuteKey = "reminderMinute"

    // Stored properties for @Observable tracking
    var hasSeenOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: hasSeenOnboardingKey) }
    }

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: remindersEnabledKey)
            if isEnabled {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    var reminderTime: Date {
        didSet {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            UserDefaults.standard.set(components.hour, forKey: reminderHourKey)
            UserDefaults.standard.set(components.minute, forKey: reminderMinuteKey)
            if isEnabled {
                scheduleReminder()
            }
        }
    }

    private init() {
        // Load initial values from UserDefaults
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
        self.isEnabled = UserDefaults.standard.bool(forKey: remindersEnabledKey)

        let hour = UserDefaults.standard.object(forKey: reminderHourKey) as? Int ?? 20
        let minute = UserDefaults.standard.object(forKey: reminderMinuteKey) as? Int ?? 0
        self.reminderTime = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func scheduleReminder() {
        cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "Time to Journal"
        content.body = "Take a moment to capture today's memories."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule reminder: \(error)")
            }
        }
    }

    func cancelReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
}
