import SwiftUI

struct ReminderOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reminderManager = ReminderManager.shared
    @State private var selectedTime = ReminderManager.shared.reminderTime
    @State private var enableReminders = true

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)

            VStack(spacing: 12) {
                Text("Daily Reminders")
                    .font(.title)
                    .bold()

                Text("Never miss a day of journaling.\nWe'll send you a gentle reminder.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                Toggle("Enable daily reminders", isOn: $enableReminders)
                    .tint(.orange)

                if enableReminders {
                    DatePicker(
                        "Reminder time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 150)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        await setupReminders()
                    }
                } label: {
                    Text(enableReminders ? "Enable Reminders" : "Continue")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    skipOnboarding()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }

    private func setupReminders() async {
        reminderManager.hasSeenOnboarding = true

        if enableReminders {
            let granted = await reminderManager.requestPermission()
            if granted {
                reminderManager.reminderTime = selectedTime
                reminderManager.isEnabled = true
            }
        }

        dismiss()
    }

    private func skipOnboarding() {
        reminderManager.hasSeenOnboarding = true
        dismiss()
    }
}

#Preview {
    ReminderOnboardingView()
}
