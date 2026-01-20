import SwiftUI

// MARK: - Time Restriction View
struct TimeRestrictionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var modeContext = ModeContext.shared
    @State private var restrictionsEnabled = false
    @State private var weekdayStartTime = Date()
    @State private var weekdayEndTime = Date()
    @State private var weekendStartTime = Date()
    @State private var weekendEndTime = Date()
    @State private var schoolModeEnabled = false
    @State private var schoolStartTime = Date()
    @State private var schoolEndTime = Date()
    @State private var allowHomeworkHelp = false
    @State private var emergencyOverrideEnabled = false
    @State private var showLockNowConfirmation = false
    @State private var showSaveSuccess = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "#9D4EDD").opacity(0.05),
                    Color(hex: "#7B2CBF").opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding()
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                ScrollView {
                    VStack(spacing: 24) {
                        // Main toggle
                        mainToggleSection

                        if restrictionsEnabled {
                            // Weekday schedule
                            weekdayScheduleSection

                            // Weekend schedule
                            weekendScheduleSection

                            // School mode
                            schoolModeSection

                            // Emergency override
                            emergencyOverrideSection

                            // Quick actions
                            quickActionsSection
                        }

                        // Current status
                        currentStatusSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Lock Now", isPresented: $showLockNowConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Lock", role: .destructive) {
                lockImmediately()
            }
        } message: {
            Text("This will immediately lock Moxie in child mode. The child will need to wait until the next allowed time window or you can unlock it with your PIN.")
        }
        .overlay(
            // Save success notification
            Group {
                if showSaveSuccess {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Settings saved successfully")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .padding(.top, 50)
                }
            }
        )
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Time Restrictions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#9D4EDD"))

                Text("Set when your child can access Moxie")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Save button
            Button(action: saveSettings) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Main Toggle Section

    private var mainToggleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $restrictionsEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.title2)
                        .foregroundColor(restrictionsEnabled ? .purple : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Time Restrictions")
                            .font(.headline)
                        Text("Control when Moxie is available for use")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Weekday Schedule Section

    private var weekdayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Weekday Schedule", systemImage: "calendar")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                TimePickerCard(
                    title: "Wake Time",
                    time: $weekdayStartTime,
                    icon: "sunrise.fill",
                    color: .orange
                )

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                TimePickerCard(
                    title: "Bedtime",
                    time: $weekdayEndTime,
                    icon: "moon.fill",
                    color: .indigo
                )
            }

            Text("Moxie will be available Monday-Friday from \(formatTime(weekdayStartTime)) to \(formatTime(weekdayEndTime))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Weekend Schedule Section

    private var weekendScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Weekend Schedule", systemImage: "calendar.badge.clock")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                TimePickerCard(
                    title: "Wake Time",
                    time: $weekendStartTime,
                    icon: "sun.max.fill",
                    color: .yellow
                )

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                TimePickerCard(
                    title: "Bedtime",
                    time: $weekendEndTime,
                    icon: "moon.stars.fill",
                    color: .purple
                )
            }

            Text("Moxie will be available Saturday-Sunday from \(formatTime(weekendStartTime)) to \(formatTime(weekendEndTime))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - School Mode Section

    private var schoolModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $schoolModeEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .font(.title3)
                        .foregroundColor(schoolModeEnabled ? .blue : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("School Hours")
                        .font(.headline)
                        Text("Restrict access during school")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)

            if schoolModeEnabled {
                HStack(spacing: 20) {
                    TimePickerCard(
                        title: "School Start",
                        time: $schoolStartTime,
                        icon: "bell.fill",
                        color: .blue
                    )

                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)

                    TimePickerCard(
                        title: "School End",
                        time: $schoolEndTime,
                        icon: "bell.badge.fill",
                        color: .green
                    )
                }

                Toggle(isOn: $allowHomeworkHelp) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .foregroundColor(.blue)
                        Text("Allow homework help mode during school")
                            .font(.subheadline)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Emergency Override Section

    private var emergencyOverrideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $emergencyOverrideEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.title3)
                        .foregroundColor(emergencyOverrideEnabled ? .red : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Emergency Override")
                            .font(.headline)
                        Text("Allow temporary access with PIN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)

            if emergencyOverrideEnabled {
                Text("When enabled, you can temporarily override time restrictions by entering your PIN. This is useful for special circumstances.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 16) {
            // Lock now button
            Button(action: { showLockNowConfirmation = true }) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Lock Now")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Grant 15 minutes button
            Button(action: grant15Minutes) {
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Grant 15 min")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Unlock until bedtime
            Button(action: unlockUntilBedtime) {
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Until Bedtime")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Current Status Section

    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current Status", systemImage: "info.circle.fill")
                .font(.headline)

            HStack(spacing: 20) {
                StatusCard(
                    title: "Mode",
                    value: modeContext.currentMode.displayName,
                    icon: modeContext.currentMode == .child ? "face.smiling" : "person.2",
                    color: modeContext.currentMode == .child ? .cyan : .purple
                )

                StatusCard(
                    title: "Status",
                    value: modeContext.isCurrentlyLocked() ? "Locked" : "Available",
                    icon: modeContext.isCurrentlyLocked() ? "lock.fill" : "lock.open.fill",
                    color: modeContext.isCurrentlyLocked() ? .red : .green
                )

                if let timeRemaining = modeContext.timeUntilNextUnlock() {
                    StatusCard(
                        title: "Unlocks In",
                        value: formatDuration(timeRemaining),
                        icon: "clock.fill",
                        color: .orange
                    )
                }
            }

            if modeContext.isEmergencyModeActive {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Emergency override active")
                        .font(.caption)
                        .foregroundColor(.orange)
                    if let expiresAt = modeContext.emergencyExpiresAt {
                        Text("• Expires \(expiresAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func loadCurrentSettings() {
        if let schedule = modeContext.autoLockSchedule {
            restrictionsEnabled = schedule.enabled

            // Load weekday times
            if let weekdayWindow = schedule.weekdayWindows.first {
                weekdayStartTime = timeComponentsToDate(weekdayWindow.startTime)
                weekdayEndTime = timeComponentsToDate(weekdayWindow.endTime)
            }

            // Load weekend times
            if let weekendWindow = schedule.weekendWindows.first {
                weekendStartTime = timeComponentsToDate(weekendWindow.startTime)
                weekendEndTime = timeComponentsToDate(weekendWindow.endTime)
            }

            // Load school mode
            if let school = schedule.schoolMode {
                schoolModeEnabled = school.enabled
                schoolStartTime = timeComponentsToDate(school.weekdayStartTime)
                schoolEndTime = timeComponentsToDate(school.weekdayEndTime)
                allowHomeworkHelp = school.allowHomeworkHelp
            }
        } else {
            // Set defaults
            setDefaultTimes()
        }
    }

    private func setDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()

        // Default weekday: 7 AM - 8 PM
        weekdayStartTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
        weekdayEndTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now

        // Default weekend: 8 AM - 9 PM
        weekendStartTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        weekendEndTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now) ?? now

        // Default school: 8 AM - 3 PM
        schoolStartTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        schoolEndTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
    }

    private func saveSettings() {
        var schedule = AutoLockSchedule()
        schedule.enabled = restrictionsEnabled

        // Save weekday window
        schedule.weekdayWindows = [
            TimeWindow(
                startTime: dateToTimeComponents(weekdayStartTime),
                endTime: dateToTimeComponents(weekdayEndTime)
            )
        ]

        // Save weekend window
        schedule.weekendWindows = [
            TimeWindow(
                startTime: dateToTimeComponents(weekendStartTime),
                endTime: dateToTimeComponents(weekendEndTime)
            )
        ]

        // Save school mode
        var school = SchoolMode()
        school.enabled = schoolModeEnabled
        school.weekdayStartTime = dateToTimeComponents(schoolStartTime)
        school.weekdayEndTime = dateToTimeComponents(schoolEndTime)
        school.allowHomeworkHelp = allowHomeworkHelp
        schedule.schoolMode = school

        // Apply to context
        modeContext.autoLockSchedule = schedule

        // Show success
        withAnimation {
            showSaveSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveSuccess = false
            }
        }
    }

    private func lockImmediately() {
        // Force lock by switching to a locked state
        modeContext.switchMode(to: .child)
        // Additional lock logic could go here
    }

    private func grant15Minutes() {
        modeContext.activateEmergencyMode(duration: 900) // 15 minutes
    }

    private func unlockUntilBedtime() {
        let calendar = Calendar.current
        let now = Date()
        let isWeekend = calendar.isDateInWeekend(now)
        let bedtime = isWeekend ? weekendEndTime : weekdayEndTime

        if let bedtimeToday = calendar.date(bySettingHour: calendar.component(.hour, from: bedtime),
                                           minute: calendar.component(.minute, from: bedtime),
                                           second: 0,
                                           of: now) {
            let duration = bedtimeToday.timeIntervalSince(now)
            if duration > 0 {
                modeContext.activateEmergencyMode(duration: duration)
            }
        }
    }

    private func timeComponentsToDate(_ components: TimeComponents) -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: components.hour,
                           minute: components.minute,
                           second: 0,
                           of: now) ?? now
    }

    private func dateToTimeComponents(_ date: Date) -> TimeComponents {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return TimeComponents(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Time Picker Card
struct TimePickerCard: View {
    let title: String
    @Binding var time: Date
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct TimeRestrictionView_Previews: PreviewProvider {
    static var previews: some View {
        TimeRestrictionView()
    }
}