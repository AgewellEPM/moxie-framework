import SwiftUI

// MARK: - PIN Setup View
struct PINSetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var createPIN = ""
    @State private var confirmPIN = ""
    @State private var securityQuestion = ""
    @State private var securityAnswer = ""
    @State private var parentEmail = ""
    @State private var pinStrength: PINStrength = .invalid
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCreating = false

    private let pinService = PINService()
    private let securityQuestions = [
        "What is your mother's maiden name?",
        "What was your first pet's name?",
        "What city were you born in?",
        "What is your favorite book?",
        "What was your first car?",
        "What is your favorite movie?",
        "What street did you grow up on?",
        "What is your father's middle name?"
    ]

    // Completion handler
    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#9D4EDD").opacity(0.9),
                    Color(hex: "#7B2CBF").opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    Text("Parent PIN Setup")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Secure your Parent Console access")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 40)

                // Progress indicator
                ProgressIndicator(currentStep: currentStep, totalSteps: 4)
                    .padding(.horizontal, 60)

                // Content based on step
                Group {
                    switch currentStep {
                    case 0:
                        createPINStep
                    case 1:
                        confirmPINStep
                    case 2:
                        securityQuestionStep
                    case 3:
                        emailStep
                    default:
                        completionStep
                    }
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 40)

                Spacer()

                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 && currentStep < 4 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                                showError = false
                            }
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: handleContinue) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(buttonTitle)
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            canContinue ?
                                LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canContinue || isCreating)
                }
                .padding(.bottom, 40)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .preferredColorScheme(.dark)
    }

    // MARK: - Step Views

    private var createPINStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Create your 6-digit PIN")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                SecureField("Enter 6-digit PIN", text: $createPIN)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .onChange(of: createPIN) { newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            createPIN = String(newValue.prefix(6))
                        }
                        // Update strength
                        if newValue.count == 6 {
                            pinStrength = pinService.validatePINStrength(newValue)
                        } else {
                            pinStrength = .invalid
                        }
                    }

                // PIN strength meter
                PINStrengthMeter(strength: pinStrength)

                // Requirements
                VStack(alignment: .leading, spacing: 8) {
                    RequirementRow(text: "Exactly 6 digits", met: createPIN.count == 6)
                    RequirementRow(text: "Numbers only", met: createPIN.allSatisfy { $0.isNumber })
                    RequirementRow(text: "Not sequential (123456)", met: pinStrength != .tooWeak)
                    RequirementRow(text: "Not repeating (111111)", met: pinStrength != .tooWeak)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }

            if showError {
                ErrorMessage(message: errorMessage)
            }
        }
    }

    private var confirmPINStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Confirm your PIN")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                SecureField("Re-enter your 6-digit PIN", text: $confirmPIN)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .onChange(of: confirmPIN) { newValue in
                        if newValue.count > 6 {
                            confirmPIN = String(newValue.prefix(6))
                        }
                    }

                if !confirmPIN.isEmpty {
                    HStack {
                        Image(systemName: confirmPIN == createPIN ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(confirmPIN == createPIN ? .green : .red)
                        Text(confirmPIN == createPIN ? "PINs match" : "PINs don't match")
                            .font(.caption)
                            .foregroundColor(confirmPIN == createPIN ? .green : .red)
                    }
                    .padding(.top, 4)
                }
            }

            if showError {
                ErrorMessage(message: errorMessage)
            }
        }
    }

    private var securityQuestionStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Set up security questions")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("These will help you recover access if you forget your PIN")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                // Question picker
                Menu {
                    ForEach(securityQuestions, id: \.self) { question in
                        Button(question) {
                            securityQuestion = question
                        }
                    }
                } label: {
                    HStack {
                        Text(securityQuestion.isEmpty ? "Select a question" : securityQuestion)
                            .foregroundColor(securityQuestion.isEmpty ? .white.opacity(0.5) : .white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .menuStyle(.borderlessButton)

                // Answer field
                TextField("Your answer", text: $securityAnswer)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                Text("Tip: Choose an answer you'll always remember")
                    .font(.caption)
                    .foregroundColor(.yellow.opacity(0.8))
                    .padding(.top, 4)
            }

            if showError {
                ErrorMessage(message: errorMessage)
            }
        }
    }

    private var emailStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parent email address")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("We'll send important notifications and alerts here")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                TextField("parent@example.com", text: $parentEmail)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                // Email features
                VStack(alignment: .leading, spacing: 8) {
                    EmailFeatureRow(icon: "flag.fill", text: "Flagged content alerts", color: .orange)
                    EmailFeatureRow(icon: "lock.trianglebadge.exclamationmark.fill", text: "Failed PIN attempts", color: .red)
                    EmailFeatureRow(icon: "clock.fill", text: "Time extension requests", color: .blue)
                    EmailFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Weekly usage reports", color: .green)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }

            if showError {
                ErrorMessage(message: errorMessage)
            }
        }
    }

    private var completionStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .scaleEffect(1.2)

            Text("PIN Setup Complete!")
                .font(.title.bold())
                .foregroundColor(.white)

            Text("Your Parent Console is now secured")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))

            VStack(alignment: .leading, spacing: 12) {
                PINCompletionRow(icon: "lock.fill", text: "6-digit PIN created")
                PINCompletionRow(icon: "questionmark.circle.fill", text: "Security question set")
                PINCompletionRow(icon: "envelope.fill", text: "Email notifications enabled")
                PINCompletionRow(icon: "shield.fill", text: "Parent Console protected")
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Properties & Methods

    private var buttonTitle: String {
        switch currentStep {
        case 0: return "Continue"
        case 1: return "Continue"
        case 2: return "Continue"
        case 3: return "Create PIN"
        default: return "Done"
        }
    }

    private var canContinue: Bool {
        switch currentStep {
        case 0:
            return createPIN.count == 6 && pinStrength != .invalid && pinStrength != .tooWeak
        case 1:
            return confirmPIN == createPIN && !confirmPIN.isEmpty
        case 2:
            return !securityQuestion.isEmpty && !securityAnswer.isEmpty
        case 3:
            return isValidEmail(parentEmail)
        default:
            return true
        }
    }

    private func handleContinue() {
        showError = false

        if currentStep == 3 {
            // Final step - create the PIN
            createParentPIN()
        } else if currentStep == 4 {
            // Completion - dismiss
            onComplete?()
            dismiss()
        } else {
            // Move to next step
            withAnimation {
                currentStep += 1
            }
        }
    }

    private func createParentPIN() {
        isCreating = true

        Task {
            do {
                // Create PIN
                try pinService.createPIN(createPIN)

                // Create parent account
                let hashedAnswer = ParentAccount.hashSecurityAnswer(securityAnswer)
                let parentAccount = ParentAccount(
                    email: parentEmail,
                    securityQuestion: securityQuestion,
                    securityAnswerHash: hashedAnswer
                )

                // Save to UserDefaults (in production, use Keychain)
                if let encoded = try? JSONEncoder().encode(parentAccount) {
                    UserDefaults.standard.set(encoded, forKey: "parentAccount")
                }

                await MainActor.run {
                    withAnimation {
                        currentStep = 4
                    }
                    isCreating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Supporting Views

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                if step < currentStep {
                    // Completed
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.white)
                        )
                } else if step == currentStep {
                    // Current
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                } else {
                    // Future
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }

                if step < totalSteps - 1 {
                    Rectangle()
                        .fill(step < currentStep ? Color.green : Color.white.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
    }
}

struct PINStrengthMeter: View {
    let strength: PINStrength

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PIN Strength:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(strength.displayName)
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: strength.color))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: strength.color))
                        .frame(width: geometry.size.width * strength.progress, height: 6)
                        .animation(.easeInOut, value: strength.progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 8)
    }
}

struct RequirementRow: View {
    let text: String
    let met: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(met ? .green : .white.opacity(0.5))
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .white : .white.opacity(0.5))
            Spacer()
        }
    }
}

struct EmailFeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}

struct PINCompletionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct ErrorMessage: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - Preview
struct PINSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PINSetupView()
    }
}