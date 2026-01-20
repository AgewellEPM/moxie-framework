import SwiftUI

struct ProviderCard: View {
    let provider: AIProvider
    @Binding var apiKey: String
    @Binding var selectedModel: String
    let isActive: Bool
    @ObservedObject var providerManager: AIProviderManager
    let onSelect: () -> Void

    @State private var showingApiKey = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(provider.color.opacity(0.2))
                            .blur(radius: 8)
                            .frame(width: 40, height: 40)
                        Image(systemName: provider.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [provider.color, provider.color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(provider.rawValue)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            // Free tier badge
                            if provider.hasFreeTier {
                                Text("FREE")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: Capsule()
                                    )
                            }
                        }

                        Text("\(provider.defaultModels.count) models available")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    // Status Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.15), in: Capsule())

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                // Free tier info banner
                if let freeTierInfo = provider.freeTierInfo {
                    HStack(spacing: 10) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)

                        Text(freeTierInfo)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .mint.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                }

                // API Key Input (only for providers that require it)
                if provider.requiresAPIKey {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("API Key")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            // Link to get API key
                            Link(destination: URL(string: provider.signupURL)!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right.square")
                                    Text("Get API Key")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                            }
                        }

                        HStack {
                            if showingApiKey {
                                TextField("Enter API Key", text: $apiKey)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .font(.system(size: 13, design: .monospaced))
                                    .onChange(of: apiKey) { _ in
                                        updateApiKey()
                                    }
                            } else {
                                SecureField("Enter API Key", text: $apiKey)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .font(.system(size: 13, design: .monospaced))
                                    .onChange(of: apiKey) { _ in
                                        updateApiKey()
                                    }
                            }

                            Button(action: { showingApiKey.toggle() }) {
                                Image(systemName: showingApiKey ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                } else {
                    // No API key needed - show info
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)

                        Text("No API key required - runs locally on your machine")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Link(destination: URL(string: provider.signupURL)!) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                Text("Download")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }

                // Model Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    Picker("", selection: $selectedModel) {
                        ForEach(provider.defaultModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .onChange(of: selectedModel) { _ in
                        updateSelectedModel()
                    }
                }

                // Set Active Button
                Button(action: {
                    onSelect()
                    providerManager.setActiveProvider(provider)
                }) {
                    HStack {
                        Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14, weight: .semibold))
                        Text(isActive ? "Active Provider" : "Set as Active")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(isActive ? provider.color : .white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        isActive ? provider.color.opacity(0.2) : Color.white.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isActive ? provider.color : Color.white.opacity(0.2), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isActive || (provider.requiresAPIKey && apiKey.isEmpty))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: isActive ? [provider.color.opacity(0.6), provider.color.opacity(0.2)] : [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isActive ? 2 : 1
                )
        )
        .shadow(color: isActive ? provider.color.opacity(0.3) : .black.opacity(0.2), radius: isActive ? 12 : 8, x: 0, y: 4)
    }

    var statusText: String {
        // Local providers don't need API key
        if !provider.requiresAPIKey {
            return "Local"
        }

        if let config = providerManager.providers.first(where: { $0.provider == provider }) {
            if !config.apiKey.isEmpty {
                switch config.validationStatus {
                case .valid: return "Connected"
                case .invalid: return "Invalid"
                case .unknown: return "Ready"
                case .testing: return "Testing..."
                }
            }
        }
        if !apiKey.isEmpty {
            return "Ready"
        }
        return "Not Set"
    }

    var statusColor: Color {
        // Local providers are always ready
        if !provider.requiresAPIKey {
            return .blue
        }

        if let config = providerManager.providers.first(where: { $0.provider == provider }) {
            if !config.apiKey.isEmpty {
                switch config.validationStatus {
                case .valid: return .green
                case .invalid: return .red
                case .unknown: return .orange
                case .testing: return .yellow
                }
            }
        }
        if !apiKey.isEmpty {
            return .orange
        }
        return .gray
    }

    func updateApiKey() {
        if var config = providerManager.providers.first(where: { $0.provider == provider }) {
            config.apiKey = apiKey
            providerManager.updateProvider(config)
        }
    }

    func updateSelectedModel() {
        if var config = providerManager.providers.first(where: { $0.provider == provider }) {
            config.selectedModel = selectedModel
            providerManager.updateProvider(config)
        }
    }
}
