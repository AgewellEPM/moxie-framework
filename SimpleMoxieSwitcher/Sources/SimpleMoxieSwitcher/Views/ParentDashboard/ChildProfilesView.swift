import SwiftUI

// MARK: - Child Profile UI Model (for ParentDashboard display)
struct ChildProfileUI: Identifiable, Codable {
    let id: UUID
    var name: String
    var nickname: String
    var avatar: String
    var avatarColor: String
    var birthDate: Date
    var interests: [String]
    var ageContentLevel: String
    var isActive: Bool
    var createdAt: Date
    var lastActiveAt: Date?
    var totalConversations: Int
    var totalScreenTime: TimeInterval

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    var ageGroup: String {
        switch age {
        case 0...3: return "Toddler"
        case 4...6: return "Preschool"
        case 7...9: return "Early Elementary"
        case 10...12: return "Pre-Teen"
        default: return "Child"
        }
    }

    init(id: UUID = UUID(), name: String, nickname: String = "", avatar: String = "person.circle.fill", avatarColor: String = "007AFF", birthDate: Date, interests: [String] = [], ageContentLevel: String = "early_elementary", isActive: Bool = true, createdAt: Date = Date(), lastActiveAt: Date? = nil, totalConversations: Int = 0, totalScreenTime: TimeInterval = 0) {
        self.id = id
        self.name = name
        self.nickname = nickname.isEmpty ? name : nickname
        self.avatar = avatar
        self.avatarColor = avatarColor
        self.birthDate = birthDate
        self.interests = interests
        self.ageContentLevel = ageContentLevel
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.totalConversations = totalConversations
        self.totalScreenTime = totalScreenTime
    }
}

// MARK: - Child Profiles View
struct ChildProfilesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var profiles: [ChildProfileUI] = []
    @State private var selectedProfile: ChildProfileUI?
    @State private var showAddProfile = false
    @State private var showEditProfile = false
    @State private var showDeleteConfirm = false
    @State private var profileToDelete: ChildProfileUI?

    private let settingsKey = "moxie_child_profiles"
    private let activeProfileKey = "moxie_active_profile"

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

                if profiles.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            activeProfileSection
                            allProfilesSection
                            statsSection
                        }
                        .padding()
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadProfiles() }
        .sheet(isPresented: $showAddProfile) {
            AddEditProfileSheet(profiles: $profiles, editingProfile: nil)
        }
        .sheet(isPresented: $showEditProfile) {
            if let profile = selectedProfile {
                AddEditProfileSheet(profiles: $profiles, editingProfile: profile)
            }
        }
        .alert("Delete Profile", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let profile = profileToDelete {
                    deleteProfile(profile)
                }
            }
        } message: {
            Text("Are you sure you want to delete \(profileToDelete?.name ?? "this profile")? This will remove all their data and cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.title)
                        .foregroundColor(.teal)
                    Text("Child Profiles")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Manage multiple children with personalized settings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showAddProfile = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Child")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.teal)
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

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.teal.opacity(0.5))

            Text("No Profiles Yet")
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text("Add your first child's profile to personalize\nMoxie's experience for them")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showAddProfile = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Child")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.teal)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Active Profile Section

    private var activeProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Currently Active", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)

            if let activeProfile = profiles.first(where: { $0.isActive }) {
                ActiveProfileCard(
                    profile: activeProfile,
                    onEdit: {
                        selectedProfile = activeProfile
                        showEditProfile = true
                    }
                )
            } else {
                Text("No active profile. Select a child below to activate.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - All Profiles Section

    private var allProfilesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("All Profiles", systemImage: "person.3.fill")
                    .font(.headline)
                Spacer()
                Text("\(profiles.count) child\(profiles.count == 1 ? "" : "ren")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(profiles) { profile in
                    ProfileCard(
                        profile: profile,
                        onActivate: { activateProfile(profile) },
                        onEdit: {
                            selectedProfile = profile
                            showEditProfile = true
                        },
                        onDelete: {
                            profileToDelete = profile
                            showDeleteConfirm = true
                        }
                    )
                }

                // Add new profile card
                Button(action: { showAddProfile = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.teal.opacity(0.5))
                        Text("Add Child")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(Color.teal.opacity(0.05))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(.teal.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Family Stats", systemImage: "chart.bar.fill")
                .font(.headline)

            HStack(spacing: 16) {
                FamilyStatCard(
                    title: "Total Conversations",
                    value: "\(profiles.reduce(0) { $0 + $1.totalConversations })",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .blue
                )

                FamilyStatCard(
                    title: "Total Screen Time",
                    value: formatTotalTime(profiles.reduce(0) { $0 + $1.totalScreenTime }),
                    icon: "clock.fill",
                    color: .orange
                )

                FamilyStatCard(
                    title: "Active Children",
                    value: "\(profiles.filter { $0.lastActiveAt != nil && Calendar.current.isDateInToday($0.lastActiveAt!) }.count)/\(profiles.count)",
                    icon: "person.fill.checkmark",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode([ChildProfileUI].self, from: data) {
            profiles = decoded
        }
    }

    private func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    private func activateProfile(_ profile: ChildProfileUI) {
        for i in 0..<profiles.count {
            profiles[i].isActive = profiles[i].id == profile.id
        }
        UserDefaults.standard.set(profile.id.uuidString, forKey: activeProfileKey)
        saveProfiles()
    }

    private func deleteProfile(_ profile: ChildProfileUI) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
    }

    private func formatTotalTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Supporting Views

struct ActiveProfileCard: View {
    let profile: ChildProfileUI
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: profile.avatarColor).opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: profile.avatar)
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: profile.avatarColor))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(profile.name)
                        .font(.title2.bold())
                    if !profile.nickname.isEmpty && profile.nickname != profile.name {
                        Text("(\(profile.nickname))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(profile.age) years old", systemImage: "birthday.cake")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(profile.ageGroup, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !profile.interests.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(profile.interests.prefix(4), id: \.self) { interest in
                            Text(interest)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.teal.opacity(0.1))
                                .foregroundColor(.teal)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                if let lastActive = profile.lastActiveAt {
                    Text("Last active: \(lastActive, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
}

struct ProfileCard: View {
    let profile: ChildProfileUI
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: profile.avatarColor).opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: profile.avatar)
                    .font(.title)
                    .foregroundColor(Color(hex: profile.avatarColor))

                if profile.isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 20, y: 20)
                }
            }

            Text(profile.nickname.isEmpty ? profile.name : profile.nickname)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            Text("\(profile.age) years • \(profile.ageGroup)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // Actions
            HStack(spacing: 8) {
                if !profile.isActive {
                    Button(action: onActivate) {
                        Text("Activate")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.teal)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(height: 180)
        .background(profile.isActive ? Color.teal.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(profile.isActive ? Color.teal.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

struct FamilyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Add/Edit Profile Sheet

struct AddEditProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var profiles: [ChildProfileUI]
    let editingProfile: ChildProfileUI?

    @State private var name = ""
    @State private var nickname = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -6, to: Date()) ?? Date()
    @State private var selectedAvatar = "person.circle.fill"
    @State private var selectedColor = "007AFF"
    @State private var interests: [String] = []
    @State private var newInterest = ""

    private let avatarOptions = [
        "person.circle.fill", "face.smiling.fill", "star.circle.fill",
        "heart.circle.fill", "sun.max.fill", "moon.fill",
        "sparkles", "leaf.fill", "flame.fill"
    ]

    private let colorOptions = [
        "007AFF", "34C759", "FF9500", "FF2D55",
        "AF52DE", "5856D6", "00C7BE", "FF3B30"
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text(editingProfile == nil ? "Add New Child" : "Edit Profile")
                .font(.title2.bold())

            ScrollView {
                VStack(spacing: 20) {
                    // Avatar Selection
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: selectedAvatar)
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: selectedColor))
                        }

                        HStack(spacing: 8) {
                            ForEach(avatarOptions, id: \.self) { avatar in
                                Button(action: { selectedAvatar = avatar }) {
                                    Image(systemName: avatar)
                                        .font(.title3)
                                        .foregroundColor(selectedAvatar == avatar ? Color(hex: selectedColor) : .gray)
                                        .frame(width: 36, height: 36)
                                        .background(selectedAvatar == avatar ? Color(hex: selectedColor).opacity(0.2) : Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            selectedColor == color ?
                                            Circle().stroke(Color.white, lineWidth: 3) : nil
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Name Fields
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name:")
                                .font(.subheadline)
                            TextField("Child's name", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nickname (optional):")
                                .font(.subheadline)
                            TextField("What Moxie calls them", text: $nickname)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Birth Date:")
                                .font(.subheadline)
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }

                    // Interests
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interests:")
                            .font(.subheadline)

                        HStack {
                            TextField("Add interest...", text: $newInterest)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)

                            Button(action: addInterest) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.teal)
                            }
                            .buttonStyle(.plain)
                            .disabled(newInterest.isEmpty)
                        }

                        if !interests.isEmpty {
                            FlowLayoutSimple(spacing: 8) {
                                ForEach(interests, id: \.self) { interest in
                                    HStack(spacing: 4) {
                                        Text(interest)
                                            .font(.caption)
                                        Button(action: { interests.removeAll { $0 == interest } }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .foregroundColor(.teal)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.teal.opacity(0.1))
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 400)

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)

                Button(editingProfile == nil ? "Add Child" : "Save Changes") {
                    saveProfile()
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.teal)
                .cornerRadius(8)
                .disabled(name.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 500)
        .onAppear {
            if let profile = editingProfile {
                name = profile.name
                nickname = profile.nickname
                birthDate = profile.birthDate
                selectedAvatar = profile.avatar
                selectedColor = profile.avatarColor
                interests = profile.interests
            }
        }
    }

    private func addInterest() {
        let interest = newInterest.trimmingCharacters(in: .whitespaces)
        if !interest.isEmpty && !interests.contains(interest) {
            interests.append(interest)
            newInterest = ""
        }
    }

    private func saveProfile() {
        if let editing = editingProfile {
            if let index = profiles.firstIndex(where: { $0.id == editing.id }) {
                profiles[index].name = name
                profiles[index].nickname = nickname.isEmpty ? name : nickname
                profiles[index].birthDate = birthDate
                profiles[index].avatar = selectedAvatar
                profiles[index].avatarColor = selectedColor
                profiles[index].interests = interests
            }
        } else {
            let profile = ChildProfileUI(
                name: name,
                nickname: nickname,
                avatar: selectedAvatar,
                avatarColor: selectedColor,
                birthDate: birthDate,
                interests: interests,
                isActive: profiles.isEmpty
            )
            profiles.append(profile)
        }

        // Save
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: "moxie_child_profiles")
        }
    }
}

// Simple flow layout for interests
struct FlowLayoutSimple<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}
