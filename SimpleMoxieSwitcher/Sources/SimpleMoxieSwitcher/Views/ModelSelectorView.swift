import SwiftUI

struct ModelSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ModelSelectorViewModel()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Divider()

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Current Model Display
                        currentModelCard

                        // Available Models
                        Text("Available Models")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top)

                        // Model Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(LLMModel.allModels) { model in
                                ModelCard(
                                    model: model,
                                    isSelected: viewModel.currentModel == model.id,
                                    isUpdating: viewModel.isUpdating
                                ) {
                                    Task {
                                        await viewModel.switchModel(to: model)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            Task {
                await viewModel.loadCurrentModel()
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("🤖 LLM Model Selector")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.ultraThinMaterial)
    }

    // MARK: - Current Model Card

    private var currentModelCard: some View {
        VStack(spacing: 12) {
            Text("Current Model")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            if let model = LLMModel.allModels.first(where: { $0.id == viewModel.currentModel }) {
                HStack(spacing: 16) {
                    Text(model.emoji)
                        .font(.system(size: 50))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(model.provider)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
            } else {
                Text("Loading...")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

// MARK: - Model Card

struct ModelCard: View {
    let model: LLMModel
    let isSelected: Bool
    let isUpdating: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Text(model.emoji)
                    .font(.system(size: 50))

                VStack(spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(model.provider)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    // Capabilities
                    HStack(spacing: 4) {
                        if model.supportsVision {
                            Image(systemName: "eye.fill")
                                .font(.caption2)
                        }
                        if model.supportsFunctionCalling {
                            Image(systemName: "function")
                                .font(.caption2)
                        }
                        if model.supportsStreaming {
                            Image(systemName: "waveform")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.white.opacity(0.6))
                }

                // Context window badge
                Text("\(model.contextWindow / 1000)K context")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white.opacity(0.8))

                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Selected")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)
                }
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected ?
                    Color.purple.opacity(0.3) :
                    (isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.purple : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isUpdating || isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - LLM Model

struct LLMModel: Identifiable, Equatable {
    let id: String
    let name: String
    let provider: String
    let emoji: String
    let contextWindow: Int
    let supportsVision: Bool
    let supportsFunctionCalling: Bool
    let supportsStreaming: Bool

    static let allModels: [LLMModel] = [
        // OpenAI Models
        LLMModel(
            id: "gpt-4o",
            name: "GPT-4o",
            provider: "OpenAI",
            emoji: "🚀",
            contextWindow: 128000,
            supportsVision: true,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),
        LLMModel(
            id: "gpt-4-turbo",
            name: "GPT-4 Turbo",
            provider: "OpenAI",
            emoji: "⚡",
            contextWindow: 128000,
            supportsVision: true,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),
        LLMModel(
            id: "gpt-4",
            name: "GPT-4",
            provider: "OpenAI",
            emoji: "🧠",
            contextWindow: 8192,
            supportsVision: false,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),
        LLMModel(
            id: "gpt-3.5-turbo",
            name: "GPT-3.5 Turbo",
            provider: "OpenAI",
            emoji: "💨",
            contextWindow: 16385,
            supportsVision: false,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),

        // Anthropic Models
        LLMModel(
            id: "claude-3-5-sonnet-20241022",
            name: "Claude 3.5 Sonnet",
            provider: "Anthropic",
            emoji: "🎭",
            contextWindow: 200000,
            supportsVision: true,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),
        LLMModel(
            id: "claude-3-opus-20240229",
            name: "Claude 3 Opus",
            provider: "Anthropic",
            emoji: "🎪",
            contextWindow: 200000,
            supportsVision: true,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),
        LLMModel(
            id: "claude-3-sonnet-20240229",
            name: "Claude 3 Sonnet",
            provider: "Anthropic",
            emoji: "🎨",
            contextWindow: 200000,
            supportsVision: true,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),
        LLMModel(
            id: "claude-3-haiku-20240307",
            name: "Claude 3 Haiku",
            provider: "Anthropic",
            emoji: "✨",
            contextWindow: 200000,
            supportsVision: true,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),

        // Google Models
        LLMModel(
            id: "gemini-pro",
            name: "Gemini Pro",
            provider: "Google",
            emoji: "💎",
            contextWindow: 32760,
            supportsVision: false,
            supportsFunctionCalling: true,
            supportsStreaming: true
        ),
        LLMModel(
            id: "gemini-pro-vision",
            name: "Gemini Pro Vision",
            provider: "Google",
            emoji: "👁️",
            contextWindow: 16384,
            supportsVision: true,
            supportsFunctionCalling: true,
            supportsStreaming: true
        )
    ]
}

// MARK: - ViewModel

@MainActor
class ModelSelectorViewModel: ObservableObject {
    @Published var currentModel: String = "gpt-4"
    @Published var isUpdating = false
    @Published var errorMessage: String?

    func loadCurrentModel() async {
        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

        let script = """
        from hive.models import MoxieDevice, PersistentData
        import json

        device = MoxieDevice.objects.filter(device_id='moxie_001').first()
        if device:
            persist = PersistentData.objects.filter(device=device).first()
            if persist and persist.data:
                model = persist.data.get('ai_model', 'gpt-4')
                print(json.dumps({'model': model}))
            else:
                print(json.dumps({'model': 'gpt-4'}))
        else:
            print(json.dumps({'model': 'gpt-4'}))
        """

        do {
            let result = try await dockerService.executePythonScript(script)
            if let data = result.data(using: .utf8),
               let json = try? JSONDecoder().decode([String: String].self, from: data),
               let model = json["model"] {
                self.currentModel = model
            }
        } catch {
            print("Failed to load current model: \(error)")
        }
    }

    func switchModel(to model: LLMModel) async {
        isUpdating = true
        errorMessage = nil

        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

        let script = """
        from hive.models import MoxieDevice, PersistentData
        import json

        device = MoxieDevice.objects.filter(device_id='moxie_001').first()
        if device:
            persist, created = PersistentData.objects.get_or_create(
                device=device,
                defaults={'data': {}}
            )
            data = persist.data or {}
            data['ai_model'] = '\(model.id)'
            persist.data = data
            persist.save()
            print(json.dumps({'success': True, 'model': '\(model.id)'}))
        else:
            print(json.dumps({'success': False, 'error': 'Device not found'}))
        """

        do {
            let result = try await dockerService.executePythonScript(script)
            if result.contains("success") {
                currentModel = model.id

                // Restart server to apply new model
                try await dockerService.restartServer()
            } else {
                errorMessage = "Failed to switch model"
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }

        isUpdating = false
    }
}

#Preview {
    ModelSelectorView()
}
