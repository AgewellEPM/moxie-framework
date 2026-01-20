import SwiftUI
import AVFoundation

// MARK: - Voice Settings
struct VoiceSettings: Codable {
    var selectedVoice: VoiceType = .friendly
    var speakingSpeed: Double = 1.0 // 0.5 to 2.0
    var pitch: Double = 1.0 // 0.5 to 2.0
    var volume: Double = 0.8 // 0.0 to 1.0
    var enableSoundEffects: Bool = true
    var soundEffectVolume: Double = 0.5
    var enableBackgroundMusic: Bool = false
    var backgroundMusicVolume: Double = 0.3
    var enableNotificationSounds: Bool = true
    var autoAdjustForAmbience: Bool = false
    var preferredLanguage: String = "en-US"

    enum VoiceType: String, Codable, CaseIterable {
        case friendly = "friendly"
        case energetic = "energetic"
        case calm = "calm"
        case playful = "playful"
        case educational = "educational"

        var displayName: String {
            switch self {
            case .friendly: return "Friendly Moxie"
            case .energetic: return "Energetic Moxie"
            case .calm: return "Calm Moxie"
            case .playful: return "Playful Moxie"
            case .educational: return "Teacher Moxie"
            }
        }

        var description: String {
            switch self {
            case .friendly: return "Warm and welcoming, perfect for everyday conversations"
            case .energetic: return "Upbeat and exciting, great for games and activities"
            case .calm: return "Soothing and gentle, ideal for bedtime or anxious moments"
            case .playful: return "Silly and fun, makes learning feel like play"
            case .educational: return "Clear and focused, optimized for learning sessions"
            }
        }

        var icon: String {
            switch self {
            case .friendly: return "face.smiling.fill"
            case .energetic: return "bolt.fill"
            case .calm: return "leaf.fill"
            case .playful: return "party.popper.fill"
            case .educational: return "graduationcap.fill"
            }
        }

        var color: Color {
            switch self {
            case .friendly: return .blue
            case .energetic: return .orange
            case .calm: return .green
            case .playful: return .pink
            case .educational: return .purple
            }
        }

        var defaultSpeed: Double {
            switch self {
            case .friendly: return 1.0
            case .energetic: return 1.15
            case .calm: return 0.9
            case .playful: return 1.1
            case .educational: return 0.95
            }
        }

        var defaultPitch: Double {
            switch self {
            case .friendly: return 1.0
            case .energetic: return 1.1
            case .calm: return 0.95
            case .playful: return 1.15
            case .educational: return 1.0
            }
        }
    }
}

// MARK: - Voice Settings View
struct VoiceSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var settings = VoiceSettings()
    @State private var isPlaying = false
    @State private var showSaveSuccess = false

    private let settingsKey = "moxie_voice_settings"
    private let synthesizer = AVSpeechSynthesizer()

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
                        voiceTypeSection
                        voiceControlsSection
                        soundEffectsSection
                        languageSection
                        previewSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadSettings() }
        .overlay(saveSuccessOverlay)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("Voice & Audio")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Customize how Moxie sounds")
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

    // MARK: - Voice Type Section

    private var voiceTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Voice Personality", systemImage: "person.wave.2.fill")
                .font(.headline)

            Text("Choose a voice style that fits your child's preference")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(VoiceSettings.VoiceType.allCases, id: \.self) { voice in
                    VoiceTypeCard(
                        voice: voice,
                        isSelected: settings.selectedVoice == voice,
                        onSelect: {
                            settings.selectedVoice = voice
                            settings.speakingSpeed = voice.defaultSpeed
                            settings.pitch = voice.defaultPitch
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Voice Controls Section

    private var voiceControlsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Voice Controls", systemImage: "slider.horizontal.3")
                .font(.headline)

            // Speaking Speed
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "tortoise.fill")
                        .foregroundColor(.blue)
                    Text("Speaking Speed")
                        .font(.subheadline)
                    Spacer()
                    Text(speedLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Slider(value: $settings.speakingSpeed, in: 0.5...1.5, step: 0.1)
                    .tint(.blue)

                HStack {
                    Text("Slower")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Faster")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Pitch
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.purple)
                    Text("Pitch")
                        .font(.subheadline)
                    Spacer()
                    Text(pitchLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Slider(value: $settings.pitch, in: 0.5...1.5, step: 0.1)
                    .tint(.purple)

                HStack {
                    Text("Lower")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Higher")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Volume
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.green)
                    Text("Voice Volume")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(settings.volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Slider(value: $settings.volume, in: 0.0...1.0, step: 0.1)
                    .tint(.green)
            }

            // Reset button
            HStack {
                Spacer()
                Button(action: resetToDefaults) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var speedLabel: String {
        if settings.speakingSpeed < 0.8 { return "Slow" }
        if settings.speakingSpeed > 1.2 { return "Fast" }
        return "Normal"
    }

    private var pitchLabel: String {
        if settings.pitch < 0.8 { return "Deep" }
        if settings.pitch > 1.2 { return "High" }
        return "Normal"
    }

    // MARK: - Sound Effects Section

    private var soundEffectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Sound Effects & Music", systemImage: "music.note.list")
                .font(.headline)

            VStack(spacing: 12) {
                // Sound Effects Toggle
                HStack {
                    Toggle(isOn: $settings.enableSoundEffects) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Sound Effects")
                                    .font(.subheadline)
                                Text("Playful sounds during interactions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if settings.enableSoundEffects {
                    HStack {
                        Text("Effects Volume")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $settings.soundEffectVolume, in: 0.0...1.0, step: 0.1)
                            .tint(.orange)
                        Text("\(Int(settings.soundEffectVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    .padding(.leading, 30)
                }

                Divider()

                // Background Music Toggle
                HStack {
                    Toggle(isOn: $settings.enableBackgroundMusic) {
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(.pink)
                            VStack(alignment: .leading) {
                                Text("Background Music")
                                    .font(.subheadline)
                                Text("Gentle music during activities")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if settings.enableBackgroundMusic {
                    HStack {
                        Text("Music Volume")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $settings.backgroundMusicVolume, in: 0.0...1.0, step: 0.1)
                            .tint(.pink)
                        Text("\(Int(settings.backgroundMusicVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    .padding(.leading, 30)
                }

                Divider()

                // Notification Sounds Toggle
                HStack {
                    Toggle(isOn: $settings.enableNotificationSounds) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Notification Sounds")
                                    .font(.subheadline)
                                Text("Sounds for alerts and achievements")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Auto Adjust Toggle
                HStack {
                    Toggle(isOn: $settings.autoAdjustForAmbience) {
                        HStack {
                            Image(systemName: "ear.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Auto-Adjust Volume")
                                    .font(.subheadline)
                                Text("Adjust based on ambient noise")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Language", systemImage: "globe")
                .font(.headline)

            Picker("Voice Language", selection: $settings.preferredLanguage) {
                Text("English (US)").tag("en-US")
                Text("English (UK)").tag("en-GB")
                Text("Spanish").tag("es-ES")
                Text("French").tag("fr-FR")
                Text("German").tag("de-DE")
                Text("Italian").tag("it-IT")
                Text("Japanese").tag("ja-JP")
                Text("Chinese (Mandarin)").tag("zh-CN")
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Preview Voice", systemImage: "play.circle.fill")
                .font(.headline)

            Text("Test how Moxie will sound with your settings")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button(action: playPreview) {
                    HStack(spacing: 8) {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title)
                        Text(isPlaying ? "Stop" : "Play Preview")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(isPlaying ? Color.red : Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview text:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\"Hi there! I'm Moxie, and I'm so happy to be your friend!\"")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }

            // Visual wave animation
            if isPlaying {
                HStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(settings.selectedVoice.color)
                            .frame(width: 4, height: CGFloat.random(in: 10...40))
                            .animation(
                                Animation.easeInOut(duration: 0.3)
                                    .repeatForever()
                                    .delay(Double(index) * 0.1),
                                value: isPlaying
                            )
                    }
                }
                .frame(height: 40)
                .frame(maxWidth: .infinity)
            }
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
                        Text("Voice settings saved")
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
           let decoded = try? JSONDecoder().decode(VoiceSettings.self, from: data) {
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

    private func resetToDefaults() {
        settings.speakingSpeed = settings.selectedVoice.defaultSpeed
        settings.pitch = settings.selectedVoice.defaultPitch
        settings.volume = 0.8
    }

    private func playPreview() {
        if isPlaying {
            synthesizer.stopSpeaking(at: .immediate)
            isPlaying = false
            return
        }

        let utterance = AVSpeechUtterance(string: "Hi there! I'm Moxie, and I'm so happy to be your friend!")
        utterance.rate = Float(settings.speakingSpeed) * AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = Float(settings.pitch)
        utterance.volume = Float(settings.volume)

        if let voice = AVSpeechSynthesisVoice(language: settings.preferredLanguage) {
            utterance.voice = voice
        }

        isPlaying = true
        synthesizer.speak(utterance)

        // Auto-stop after a timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isPlaying = false
        }
    }
}

// MARK: - Supporting Views

struct VoiceTypeCard: View {
    let voice: VoiceSettings.VoiceType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: voice.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : voice.color)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? voice.color : voice.color.opacity(0.2))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isSelected ? voice.color : .primary)
                    Text(voice.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(voice.color)
                }
            }
            .padding()
            .background(isSelected ? voice.color.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? voice.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
