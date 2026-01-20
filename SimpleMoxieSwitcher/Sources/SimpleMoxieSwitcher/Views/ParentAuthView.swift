import SwiftUI

// MARK: - Parent Authentication View
struct ParentAuthView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var modeContext = ModeContext.shared
    @State private var pinDigits: [String] = Array(repeating: "", count: 6)
    @State private var currentDigitIndex = 0
    @State private var isAuthenticating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showForgotPIN = false
    @State private var lockScale: CGFloat = 1.0
    @State private var attemptCount = 0

    private let pinService = PINService()

    // Completion handler for successful authentication
    var onSuccess: (() -> Void)?

    var body: some View {
        ZStack {
            // Background gradient - purple for parent mode
            LinearGradient(
                colors: [
                    Color(hex: "#9D4EDD").opacity(0.9),
                    Color(hex: "#7B2CBF").opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Blurred child mode indicator in background
            VStack {
                HStack {
                    Spacer()
                    Text("Child Mode Active")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                        .padding(8)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(20)
                        .blur(radius: 2)
                }
                .padding()
                Spacer()
            }

            VStack(spacing: 40) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                // Lock icon with animation
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(lockScale)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            lockScale = 1.1
                        }
                    }

                // Title
                VStack(spacing: 12) {
                    Text("Enter PIN")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Access Parent Console")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }

                // PIN Display
                HStack(spacing: 16) {
                    ForEach(0..<6, id: \.self) { index in
                        PINDigitView(
                            digit: index < pinDigits.count ? pinDigits[index] : "",
                            isFocused: index == currentDigitIndex,
                            hasError: showError
                        )
                    }
                }
                .padding(.horizontal, 40)

                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                }

                // Lockout timer
                if modeContext.isPINLocked, let remaining = modeContext.pinLockoutTimeRemaining {
                    LockoutTimerView(timeRemaining: remaining)
                }

                // Numeric Keypad
                if !modeContext.isPINLocked {
                    NumericKeypadView(onDigitTap: handleDigitInput, onDelete: handleDelete)
                        .padding(.horizontal, 40)
                }

                // Forgot PIN button
                Button(action: { showForgotPIN = true }) {
                    Text("Forgot PIN?")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }
                .buttonStyle(.plain)
                .disabled(modeContext.isPINLocked)

                Spacer()
            }
            .padding(.vertical, 40)
        }
        .frame(minWidth: 500, minHeight: 700)
        .sheet(isPresented: $showForgotPIN) {
            ForgotPINView()
        }
        .onChange(of: pinDigits) { _ in
            checkPINIfComplete()
        }
        .onAppear {
            // Clear old PIN attempts on appear
            modeContext.clearOldPINAttempts()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Parent Authentication")
        .accessibilityHint("Enter your 6-digit PIN to access the Parent Console")
    }

    // MARK: - Input Handling

    private func handleDigitInput(_ digit: String) {
        guard currentDigitIndex < 6 else { return }
        guard !modeContext.isPINLocked else { return }

        withAnimation(.easeInOut(duration: 0.1)) {
            if currentDigitIndex < pinDigits.count {
                pinDigits[currentDigitIndex] = digit
            }
            currentDigitIndex = min(currentDigitIndex + 1, 5)
        }
    }

    private func handleDelete() {
        guard currentDigitIndex > 0 else { return }

        withAnimation(.easeInOut(duration: 0.1)) {
            currentDigitIndex -= 1
            if currentDigitIndex < pinDigits.count {
                pinDigits[currentDigitIndex] = ""
            }
        }
    }

    private func checkPINIfComplete() {
        guard pinDigits.filter({ !$0.isEmpty }).count == 6 else { return }
        guard !isAuthenticating else { return }

        let enteredPIN = pinDigits.joined()
        validatePIN(enteredPIN)
    }

    private func validatePIN(_ pin: String) {
        isAuthenticating = true

        Task {
            do {
                let isValid = try pinService.validatePIN(pin)

                await MainActor.run {
                    if isValid {
                        // Success
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            lockScale = 0.8
                        }

                        // Switch to adult mode
                        modeContext.switchMode(to: .adult)

                        // Call success handler
                        onSuccess?()

                        // Dismiss after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    } else {
                        // Failed attempt
                        attemptCount += 1
                        showPINError()
                    }
                    isAuthenticating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isAuthenticating = false
                    resetPIN()
                }
            }
        }
    }

    private func showPINError() {
        withAnimation(.default) {
            if modeContext.isPINLocked {
                errorMessage = "Too many attempts. Please wait."
            } else {
                let remainingAttempts = 3 - attemptCount
                if remainingAttempts > 0 {
                    errorMessage = "Incorrect PIN. \(remainingAttempts) attempt\(remainingAttempts == 1 ? "" : "s") remaining."
                } else {
                    errorMessage = "PIN locked. Please try again later."
                }
            }
            showError = true
        }

        // Shake animation
        withAnimation(.default.repeatCount(3, autoreverses: true).speed(3)) {
            lockScale = 0.95
        }

        resetPIN()

        // Clear error after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showError = false
            }
        }
    }

    private func resetPIN() {
        pinDigits = Array(repeating: "", count: 6)
        currentDigitIndex = 0
    }
}

// MARK: - PIN Digit View
struct PINDigitView: View {
    let digit: String
    let isFocused: Bool
    let hasError: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            hasError ? Color.red :
                            (isFocused ? Color.white : Color.white.opacity(0.3)),
                            lineWidth: 2
                        )
                )

            if !digit.isEmpty {
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .transition(.scale)
            }
        }
        .frame(width: 50, height: 60)
        .animation(.easeInOut(duration: 0.2), value: digit)
        .animation(.easeInOut(duration: 0.2), value: hasError)
        .accessibilityElement()
        .accessibilityLabel(digit.isEmpty ? "Empty digit" : "Digit entered")
        .accessibilityHidden(true)
    }
}

// MARK: - Numeric Keypad View
struct NumericKeypadView: View {
    let onDigitTap: (String) -> Void
    let onDelete: () -> Void

    let digits = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "delete"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(digits, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { digit in
                        if digit.isEmpty {
                            Spacer()
                                .frame(width: 80, height: 60)
                        } else if digit == "delete" {
                            Button(action: onDelete) {
                                Image(systemName: "delete.left.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 60)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete")
                        } else {
                            Button(action: { onDigitTap(digit) }) {
                                Text(digit)
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 60)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Digit \(digit)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Lockout Timer View
struct LockoutTimerView: View {
    let timeRemaining: TimeInterval
    @State private var displayTime = ""

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Locked for \(displayTime)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            updateDisplayTime()
            startTimer()
        }
    }

    private func updateDisplayTime() {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        displayTime = String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            updateDisplayTime()
            if timeRemaining <= 0 {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Forgot PIN View
struct ForgotPINView: View {
    @Environment(\.dismiss) var dismiss
    @State private var securityAnswer = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var currentStep = 0
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
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
                HStack {
                    Text("Reset PIN")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                // Content based on step
                if currentStep == 0 {
                    // Security question
                    VStack(spacing: 20) {
                        Text("Answer your security question")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("What is your mother's maiden name?")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))

                        SecureField("Security answer", text: $securityAnswer)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                } else {
                    // New PIN entry
                    VStack(spacing: 20) {
                        Text("Create a new PIN")
                            .font(.headline)
                            .foregroundColor(.white)

                        SecureField("New 6-digit PIN", text: $newPIN)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)

                        SecureField("Confirm PIN", text: $confirmPIN)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                }

                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()

                Button(action: handleContinue) {
                    Text(currentStep == 0 ? "Verify" : "Reset PIN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 500)
    }

    private func handleContinue() {
        // Implementation would verify security answer and reset PIN
        // This is a simplified version
        if currentStep == 0 {
            currentStep = 1
        } else {
            if newPIN == confirmPIN && newPIN.count == 6 {
                // Reset PIN logic
                dismiss()
            } else {
                errorMessage = "PINs don't match or invalid length"
                showError = true
            }
        }
    }
}

// MARK: - Preview
struct ParentAuthView_Previews: PreviewProvider {
    static var previews: some View {
        ParentAuthView()
            .preferredColorScheme(.dark)
    }
}