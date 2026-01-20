import SwiftUI

// MARK: - Quiet Hours Settings
struct QuietHoursSettings: Codable {
    var isEnabled: Bool = true
    var schedules: [QuietSchedule] = []
    var quietMessage: String = "Moxie is taking a nap right now. Come back later!"
    var allowEmergencyOverride: Bool = true
    var emergencyKeyword: String = "emergency"
    var notifyParentOnAttempt: Bool = true

    struct QuietSchedule: Codable, Identifiable {
        let id: UUID
        var name: String
        var startTime: Date
        var endTime: Date
        var daysOfWeek: [Int] // 1 = Sunday, 7 = Saturday
        var isEnabled: Bool

        init(id: UUID = UUID(), name: String, startTime: Date, endTime: Date, daysOfWeek: [Int], isEnabled: Bool = true) {
            self.id = id
            self.name = name
            self.startTime = startTime
            self.endTime = endTime
            self.daysOfWeek = daysOfWeek
            self.isEnabled = isEnabled
        }

        var daysDescription: String {
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            if daysOfWeek.count == 7 {
                return "Every day"
            } else if daysOfWeek == [2, 3, 4, 5, 6] {
                return "Weekdays"
            } else if daysOfWeek == [1, 7] {
                return "Weekends"
            } else {
                return daysOfWeek.map { dayNames[$0 - 1] }.joined(separator: ", ")
            }
        }
    }
}

// MARK: - Quiet Hours View
struct QuietHoursView: View {
    @Environment(\.dismiss) var dismiss
    @State private var settings = QuietHoursSettings()
    @State private var showAddSchedule = false
    @State private var editingSchedule: QuietHoursSettings.QuietSchedule?
    @State private var showSaveSuccess = false

    private let settingsKey = "moxie_quiet_hours_settings"

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "9D4EDD").opacity(0.05),
                    Color(hex: "7B2CBF").opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding()
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                ScrollView {
                    VStack(spacing: 24) {
                        enableToggleSection
                        schedulesSection
                        quietMessageSection
                        emergencySection
                        previewSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadSettings() }
        .overlay(saveSuccessOverlay)
        .sheet(isPresented: $showAddSchedule) {
            AddScheduleSheet(settings: $settings, editingSchedule: $editingSchedule)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title)
                        .foregroundColor(.indigo)
                    Text("Quiet Hours")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Set times when Moxie takes a break")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

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

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Enable Toggle Section

    private var enableToggleSection: some View {
        HStack(spacing: 16) {
            Image(systemName: settings.isEnabled ? "moon.fill" : "moon")
                .font(.system(size: 40))
                .foregroundColor(settings.isEnabled ? .indigo : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text("Quiet Hours")
                    .font(.headline)
                Text(settings.isEnabled ? "Moxie will rest during scheduled times" : "Quiet hours are disabled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $settings.isEnabled)
                .labelsHidden()
                .scaleEffect(1.2)
        }
        .padding()
        .background(settings.isEnabled ? Color.indigo.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Schedules Section

    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Schedules", systemImage: "calendar.badge.clock")
                    .font(.headline)

                Spacer()

                Button(action: { showAddSchedule = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Schedule")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.indigo)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            if settings.schedules.isEmpty {
                emptySchedulesView
            } else {
                ForEach(settings.schedules) { schedule in
                    ScheduleCard(
                        schedule: schedule,
                        onEdit: {
                            editingSchedule = schedule
                            showAddSchedule = true
                        },
                        onDelete: {
                            settings.schedules.removeAll { $0.id == schedule.id }
                        },
                        onToggle: {
                            if let index = settings.schedules.firstIndex(where: { $0.id == schedule.id }) {
                                settings.schedules[index].isEnabled.toggle()
                            }
                        }
                    )
                }
            }

            // Quick presets
            quickPresetsSection
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var emptySchedulesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No schedules yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Add quiet time schedules for bedtime, school hours, or family time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                QuickPresetButton(title: "Bedtime", icon: "bed.double.fill", color: .indigo) {
                    addBedtimeSchedule()
                }

                QuickPresetButton(title: "School Hours", icon: "building.2.fill", color: .blue) {
                    addSchoolSchedule()
                }

                QuickPresetButton(title: "Family Dinner", icon: "fork.knife", color: .orange) {
                    addDinnerSchedule()
                }

                QuickPresetButton(title: "Homework Time", icon: "book.fill", color: .green) {
                    addHomeworkSchedule()
                }
            }
        }
    }

    // MARK: - Quiet Message Section

    private var quietMessageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Quiet Time Message", systemImage: "text.bubble.fill")
                .font(.headline)

            Text("What Moxie says when a child tries to chat during quiet hours:")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: $settings.quietMessage)
                .font(.body)
                .frame(height: 80)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            // Preset messages
            HStack(spacing: 8) {
                ForEach(presetMessages, id: \.self) { message in
                    Button(action: { settings.quietMessage = message }) {
                        Text(message.prefix(20) + "...")
                            .font(.caption)
                            .foregroundColor(.indigo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.indigo.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var presetMessages: [String] {
        [
            "Moxie is taking a nap right now. Come back later!",
            "It's quiet time! Let's play again soon.",
            "Shh... Moxie is sleeping. Sweet dreams!",
            "Time for a break! See you after quiet time."
        ]
    }

    // MARK: - Emergency Section

    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Emergency Override", systemImage: "exclamationmark.shield.fill")
                .font(.headline)

            Toggle(isOn: $settings.allowEmergencyOverride) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Allow emergency keyword")
                        .font(.subheadline)
                    Text("Child can say a special word to reach Moxie during quiet hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if settings.allowEmergencyOverride {
                HStack {
                    Text("Emergency keyword:")
                        .font(.subheadline)
                    TextField("emergency", text: $settings.emergencyKeyword)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(width: 150)
                }
            }

            Toggle(isOn: $settings.notifyParentOnAttempt) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notify on quiet hour attempts")
                        .font(.subheadline)
                    Text("Get notified when your child tries to use Moxie during quiet hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Current Status", systemImage: "clock.fill")
                .font(.headline)

            let currentStatus = getCurrentStatus()

            HStack(spacing: 16) {
                Image(systemName: currentStatus.isQuiet ? "moon.zzz.fill" : "sun.max.fill")
                    .font(.system(size: 40))
                    .foregroundColor(currentStatus.isQuiet ? .indigo : .yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentStatus.isQuiet ? "Quiet Time Active" : "Moxie is Awake")
                        .font(.headline)
                    Text(currentStatus.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(currentStatus.isQuiet ? Color.indigo.opacity(0.1) : Color.yellow.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Save Success Overlay

    private var saveSuccessOverlay: some View {
        Group {
            if showSaveSuccess {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Quiet hours saved")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.green.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    Spacer()
                }
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Helpers

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(QuietHoursSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }

        withAnimation {
            showSaveSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveSuccess = false
            }
        }
    }

    private func getCurrentStatus() -> (isQuiet: Bool, message: String) {
        guard settings.isEnabled else {
            return (false, "Quiet hours are disabled")
        }

        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)

        for schedule in settings.schedules where schedule.isEnabled && schedule.daysOfWeek.contains(currentWeekday) {
            let startComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
            let currentComponents = calendar.dateComponents([.hour, .minute], from: now)

            if let startHour = startComponents.hour, let startMinute = startComponents.minute,
               let endHour = endComponents.hour, let endMinute = endComponents.minute,
               let currentHour = currentComponents.hour, let currentMinute = currentComponents.minute {

                let startMinutes = startHour * 60 + startMinute
                let endMinutes = endHour * 60 + endMinute
                let currentMinutes = currentHour * 60 + currentMinute

                if currentMinutes >= startMinutes && currentMinutes < endMinutes {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    return (true, "\(schedule.name) until \(formatter.string(from: schedule.endTime))")
                }
            }
        }

        // Find next quiet time
        if let nextSchedule = findNextSchedule() {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return (false, "Next quiet time: \(nextSchedule.name) at \(formatter.string(from: nextSchedule.startTime))")
        }

        return (false, "No quiet hours scheduled")
    }

    private func findNextSchedule() -> QuietHoursSettings.QuietSchedule? {
        settings.schedules.filter { $0.isEnabled }.first
    }

    // MARK: - Quick Presets

    private func addBedtimeSchedule() {
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.hour = 20
        startComponents.minute = 0
        var endComponents = DateComponents()
        endComponents.hour = 7
        endComponents.minute = 0

        let schedule = QuietHoursSettings.QuietSchedule(
            name: "Bedtime",
            startTime: calendar.date(from: startComponents) ?? Date(),
            endTime: calendar.date(from: endComponents) ?? Date(),
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7]
        )
        settings.schedules.append(schedule)
    }

    private func addSchoolSchedule() {
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.hour = 8
        startComponents.minute = 0
        var endComponents = DateComponents()
        endComponents.hour = 15
        endComponents.minute = 0

        let schedule = QuietHoursSettings.QuietSchedule(
            name: "School Hours",
            startTime: calendar.date(from: startComponents) ?? Date(),
            endTime: calendar.date(from: endComponents) ?? Date(),
            daysOfWeek: [2, 3, 4, 5, 6] // Mon-Fri
        )
        settings.schedules.append(schedule)
    }

    private func addDinnerSchedule() {
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.hour = 18
        startComponents.minute = 0
        var endComponents = DateComponents()
        endComponents.hour = 19
        endComponents.minute = 0

        let schedule = QuietHoursSettings.QuietSchedule(
            name: "Family Dinner",
            startTime: calendar.date(from: startComponents) ?? Date(),
            endTime: calendar.date(from: endComponents) ?? Date(),
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7]
        )
        settings.schedules.append(schedule)
    }

    private func addHomeworkSchedule() {
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.hour = 16
        startComponents.minute = 0
        var endComponents = DateComponents()
        endComponents.hour = 17
        endComponents.minute = 30

        let schedule = QuietHoursSettings.QuietSchedule(
            name: "Homework Time",
            startTime: calendar.date(from: startComponents) ?? Date(),
            endTime: calendar.date(from: endComponents) ?? Date(),
            daysOfWeek: [2, 3, 4, 5, 6] // Mon-Fri
        )
        settings.schedules.append(schedule)
    }
}

// MARK: - Supporting Views

struct ScheduleCard: View {
    let schedule: QuietHoursSettings.QuietSchedule
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Toggle("", isOn: .constant(schedule.isEnabled))
                .labelsHidden()
                .onTapGesture { onToggle() }

            Image(systemName: scheduleIcon)
                .font(.title2)
                .foregroundColor(schedule.isEnabled ? .indigo : .gray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(schedule.isEnabled ? .primary : .secondary)

                HStack {
                    Text(timeRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(schedule.daysDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(schedule.isEnabled ? Color.indigo.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var scheduleIcon: String {
        switch schedule.name.lowercased() {
        case let name where name.contains("bed"): return "bed.double.fill"
        case let name where name.contains("school"): return "building.2.fill"
        case let name where name.contains("dinner"): return "fork.knife"
        case let name where name.contains("homework"): return "book.fill"
        default: return "clock.fill"
        }
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: schedule.startTime)) - \(formatter.string(from: schedule.endTime))"
    }
}

struct QuickPresetButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct AddScheduleSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var settings: QuietHoursSettings
    @Binding var editingSchedule: QuietHoursSettings.QuietSchedule?

    @State private var name = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedDays: Set<Int> = []

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 24) {
            Text(editingSchedule == nil ? "Add Schedule" : "Edit Schedule")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text("Schedule Name:")
                    .font(.subheadline)
                TextField("e.g., Bedtime", text: $name)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Time:")
                        .font(.subheadline)
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("End Time:")
                        .font(.subheadline)
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Days:")
                    .font(.subheadline)

                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { day in
                        DayButton(
                            day: dayNames[day - 1],
                            isSelected: selectedDays.contains(day)
                        ) {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    Button("Weekdays") { selectedDays = [2, 3, 4, 5, 6] }
                        .font(.caption)
                        .foregroundColor(.indigo)
                    Button("Weekends") { selectedDays = [1, 7] }
                        .font(.caption)
                        .foregroundColor(.indigo)
                    Button("Every Day") { selectedDays = [1, 2, 3, 4, 5, 6, 7] }
                        .font(.caption)
                        .foregroundColor(.indigo)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)

                Button(editingSchedule == nil ? "Add Schedule" : "Save Changes") {
                    saveSchedule()
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.indigo)
                .cornerRadius(8)
                .disabled(name.isEmpty || selectedDays.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 450)
        .onAppear {
            if let schedule = editingSchedule {
                name = schedule.name
                startTime = schedule.startTime
                endTime = schedule.endTime
                selectedDays = Set(schedule.daysOfWeek)
            }
        }
    }

    private func saveSchedule() {
        if let editing = editingSchedule {
            if let index = settings.schedules.firstIndex(where: { $0.id == editing.id }) {
                settings.schedules[index] = QuietHoursSettings.QuietSchedule(
                    id: editing.id,
                    name: name,
                    startTime: startTime,
                    endTime: endTime,
                    daysOfWeek: Array(selectedDays).sorted(),
                    isEnabled: editing.isEnabled
                )
            }
        } else {
            let schedule = QuietHoursSettings.QuietSchedule(
                name: name,
                startTime: startTime,
                endTime: endTime,
                daysOfWeek: Array(selectedDays).sorted()
            )
            settings.schedules.append(schedule)
        }
        editingSchedule = nil
    }
}

struct DayButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.indigo : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
