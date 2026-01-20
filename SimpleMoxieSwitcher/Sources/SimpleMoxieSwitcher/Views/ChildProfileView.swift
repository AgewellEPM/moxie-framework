import SwiftUI

struct ChildProfileView: View {
    @StateObject private var viewModel = ChildProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Dark background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Child Profile")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(.ultraThinMaterial)

                ScrollView {
                    VStack(spacing: 20) {
                    // Icon and Description
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)

                        Text("Help OpenMoxie get to know your child better")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)

                    Divider()

                    // Profile Form
                    VStack(alignment: .leading, spacing: 20) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Child's Name", systemImage: "person.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                            TextField("Enter name", text: $viewModel.profile.name)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                        }

                        // Birthday
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Birthday", systemImage: "calendar")
                                .font(.headline)
                                .foregroundColor(.white)

                            Toggle("Set Birthday", isOn: $viewModel.hasBirthday)
                                .toggleStyle(.switch)
                                .foregroundColor(.white)

                            if viewModel.hasBirthday {
                                DatePicker(
                                    "Date of Birth",
                                    selection: Binding(
                                        get: { viewModel.profile.birthday ?? Date() },
                                        set: { viewModel.profile.birthday = $0 }
                                    ),
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)

                                if let age = viewModel.profile.age {
                                    Text("Age: \(age) years old")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.top, 4)
                                }
                            }
                        }

                        Divider()

                        // Interests
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Interests & Hobbies", systemImage: "star.fill")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("What does your child enjoy? (e.g., dinosaurs, drawing, soccer)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            HStack {
                                TextField("Add an interest", text: $viewModel.newInterest)
                                    .textFieldStyle(.roundedBorder)

                                Button(action: viewModel.addInterest) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                            }

                            // Display interests as tags
                            if !viewModel.profile.interests.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(viewModel.profile.interests, id: \.self) { interest in
                                        HStack(spacing: 4) {
                                            Text(interest)
                                            Button(action: { viewModel.removeInterest(interest) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }

                        Divider()

                        // Personal Goals
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Personal Goals", systemImage: "target")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Goals for your child or yourself (e.g., learn to read, build confidence)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            HStack {
                                TextField("Add a goal", text: $viewModel.newGoal)
                                    .textFieldStyle(.roundedBorder)

                                Button(action: viewModel.addGoal) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                            }

                            // Display goals as list
                            if !viewModel.profile.personalGoals.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.profile.personalGoals, id: \.self) { goal in
                                        HStack {
                                            Image(systemName: "checkmark.circle")
                                                .foregroundColor(.orange)
                                            Text(goal)
                                            Spacer()
                                            Button(action: { viewModel.removeGoal(goal) }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(8)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        Divider()

                        // Things to Remember
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Things for OpenMoxie to Remember", systemImage: "brain.head.profile")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Important details, preferences, or context about your child")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            TextEditor(text: $viewModel.profile.thingsToRemember)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )

                            Text("Examples: allergies, favorite colors, siblings' names, learning challenges, communication preferences")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                                .italic()
                        }

                        Divider()

                        // AI Context Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Label("What OpenMoxie Will Know", systemImage: "doc.text")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(viewModel.profile.contextForAI)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Save Button
                    Button(action: {
                        viewModel.saveProfile()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Profile")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.loadProfile()
        }
    }
}

// ViewModel
@MainActor
class ChildProfileViewModel: ObservableObject {
    @Published var profile = ChildProfile()
    @Published var newInterest = ""
    @Published var newGoal = ""
    @Published var hasBirthday = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let childProfileService: ChildProfileService

    init(childProfileService: ChildProfileService? = nil) {
        self.childProfileService = childProfileService ?? DIContainer.shared.resolve(ChildProfileService.self)
    }

    func loadProfile() {
        Task {
            do {
                if let loadedProfile = try await childProfileService.loadProfile() {
                    profile = loadedProfile
                    hasBirthday = loadedProfile.birthday != nil
                } else {
                    // No profile exists yet, use default
                    profile = ChildProfile()
                    hasBirthday = false
                }
            } catch {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
                print("Error loading profile: \(error)")
            }
        }
    }

    func saveProfile() {
        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                if !hasBirthday {
                    profile.birthday = nil
                }

                try await childProfileService.saveProfile(profile)
                print("Profile saved successfully to database")
            } catch {
                errorMessage = "Failed to save profile: \(error.localizedDescription)"
                print("Error saving profile: \(error)")
            }
        }
    }

    func addInterest() {
        let trimmed = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profile.interests.append(trimmed)
        newInterest = ""
    }

    func removeInterest(_ interest: String) {
        profile.interests.removeAll { $0 == interest }
    }

    func addGoal() {
        let trimmed = newGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profile.personalGoals.append(trimmed)
        newGoal = ""
    }

    func removeGoal(_ goal: String) {
        profile.personalGoals.removeAll { $0 == goal }
    }
}

// Flow Layout for interest tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    ChildProfileView()
}
