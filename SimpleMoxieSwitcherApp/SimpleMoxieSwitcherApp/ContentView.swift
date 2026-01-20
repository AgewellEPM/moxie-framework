//
//  ContentView.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var controller = PersonalityController()
    @StateObject private var setupManager = SetupManager()
    @State private var showCustomCreator = false
    @State private var showFaceSelector = false
    @State private var showControls = false
    @State private var showAppearance = false
    @State private var showConversations = false
    @State private var showSettings = false
    @State private var showDocumentation = false
    @State private var setupComplete = false
    @State private var isCheckingStatus = true
    @State private var selectedRobot: String = "Moxie"

    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.12, green: 0.12, blue: 0.14)
                .ignoresSafeArea()

            if isCheckingStatus {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Checking system status...")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            } else if !setupManager.setupComplete && !setupComplete {
                // Show setup wizard
                SetupWizardView(setupManager: setupManager, isComplete: $setupComplete)
            } else {
                // Main dashboard
                MainDashboardView(
                    controller: controller,
                    setupManager: setupManager,
                    selectedRobot: $selectedRobot,
                    showCustomCreator: $showCustomCreator,
                    showFaceSelector: $showFaceSelector,
                    showControls: $showControls,
                    showAppearance: $showAppearance,
                    showConversations: $showConversations,
                    showSettings: $showSettings,
                    showDocumentation: $showDocumentation
                )
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .onAppear {
            Task {
                await setupManager.performFullCheck()
                isCheckingStatus = false
                if setupManager.setupComplete {
                    setupComplete = true
                }
            }
        }
        .sheet(isPresented: $showCustomCreator) {
            CustomPersonalityView(controller: controller)
        }
        .sheet(isPresented: $showFaceSelector) {
            FaceSelectorView(controller: controller)
        }
        .sheet(isPresented: $showControls) {
            ControlsView(controller: controller)
        }
        .sheet(isPresented: $showAppearance) {
            AppearanceCustomizationView(controller: controller)
        }
        .sheet(isPresented: $showConversations) {
            ConversationsView(controller: controller)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(setupManager: setupManager)
        }
        .sheet(isPresented: $showDocumentation) {
            DocumentationView()
        }
    }
}

// MARK: - Main Dashboard

struct MainDashboardView: View {
    @ObservedObject var controller: PersonalityController
    @ObservedObject var setupManager: SetupManager
    @Binding var selectedRobot: String
    @Binding var showCustomCreator: Bool
    @Binding var showFaceSelector: Bool
    @Binding var showControls: Bool
    @Binding var showAppearance: Bool
    @Binding var showConversations: Bool
    @Binding var showSettings: Bool
    @Binding var showDocumentation: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            DashboardHeader(
                setupManager: setupManager,
                selectedRobot: $selectedRobot
            )

            // Status bar
            StatusBar(setupManager: setupManager, controller: controller)

            // Main content
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 15)
                ], spacing: 15) {
                    // Docker control
                    DashboardTile(
                        icon: "server.rack",
                        title: "Start Docker",
                        color: .blue,
                        action: {
                            Task {
                                await setupManager.startOpenMoxie()
                            }
                        }
                    )

                    // Child Profile
                    DashboardTile(
                        icon: "face.smiling",
                        title: "Child Profile",
                        color: .orange,
                        action: { showFaceSelector = true }
                    )

                    // Custom Personality
                    DashboardTile(
                        icon: "sparkles",
                        title: "Custom Personality",
                        color: .purple,
                        action: { showCustomCreator = true }
                    )

                    // Appearance
                    DashboardTile(
                        icon: "paintbrush.fill",
                        title: "Appearance",
                        color: .cyan,
                        action: { showAppearance = true }
                    )

                    // Conversations
                    DashboardTile(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "conversations",
                        color: .green,
                        action: { showConversations = true }
                    )

                    // Story Time
                    DashboardTile(
                        icon: "book.fill",
                        title: "Story Time",
                        color: .red,
                        action: { }
                    )

                    // Learning
                    DashboardTile(
                        icon: "graduationcap.fill",
                        title: "Learning",
                        color: .indigo,
                        action: { }
                    )

                    // Language
                    DashboardTile(
                        icon: "globe",
                        title: "Language",
                        color: .teal,
                        action: { }
                    )

                    // Music
                    DashboardTile(
                        icon: "music.mic",
                        title: "Music",
                        color: .pink,
                        action: { }
                    )

                    // Smart Home
                    DashboardTile(
                        icon: "house.fill",
                        title: "Smart Home",
                        color: .blue,
                        action: { }
                    )

                    // Puppet Mode
                    DashboardTile(
                        icon: "theatermasks.fill",
                        title: "Puppet Mode",
                        color: .red,
                        action: { showControls = true }
                    )

                    // Games
                    DashboardTile(
                        icon: "gamecontroller.fill",
                        title: "Games",
                        color: .blue,
                        action: { }
                    )

                    // Settings
                    DashboardTile(
                        icon: "gearshape.fill",
                        title: "Settings",
                        color: .yellow,
                        action: { showSettings = true }
                    )

                    // Documentation
                    DashboardTile(
                        icon: "doc.text.fill",
                        title: "Documentation",
                        color: .gray,
                        action: { showDocumentation = true }
                    )

                    // Default Moxie
                    DashboardTile(
                        icon: "cpu",
                        title: "Default Moxie",
                        color: .cyan,
                        action: {
                            Task {
                                await controller.switchPersonality(.defaultMoxie)
                            }
                        }
                    )
                }
                .padding(25)
            }
        }
    }
}

// MARK: - Dashboard Header

struct DashboardHeader: View {
    @ObservedObject var setupManager: SetupManager
    @Binding var selectedRobot: String

    var body: some View {
        VStack(spacing: 15) {
            Text("Moxie 2.0 Controller")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            HStack {
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(setupManager.isOpenMoxieRunning ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(setupManager.isOpenMoxieRunning ? "Online" : "Offline")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.callout)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)

                Spacer()

                // Robot selector dropdown
                Menu {
                    Button("Moxie") { selectedRobot = "Moxie" }
                    Button("Add Robot...") { }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Image(systemName: "flag.fill")
                            .foregroundColor(.red)
                        Text(selectedRobot)
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 30)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Status Bar

struct StatusBar: View {
    @ObservedObject var setupManager: SetupManager
    @ObservedObject var controller: PersonalityController

    var body: some View {
        if let status = controller.statusMessage {
            HStack {
                if status.contains("SUCCESS") || status.contains("success") {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if status.contains("Error") || status.contains("Failed") {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                } else {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                }
                Text(status)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                status.contains("Error") || status.contains("Failed")
                    ? Color.red.opacity(0.3)
                    : Color.white.opacity(0.1)
            )
            .cornerRadius(8)
            .padding(.bottom, 10)
        }

        if !setupManager.isOpenMoxieRunning {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Failed to start Docker: docker command not found")
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.2))
            .cornerRadius(8)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Dashboard Tile

struct DashboardTile: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 140, height: 120)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color,
                            color.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Glossy highlight
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var setupManager: SetupManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)

            Form {
                Section("Server Status") {
                    HStack {
                        Text("Docker")
                        Spacer()
                        Text(setupManager.isDockerRunning ? "Running" : "Stopped")
                            .foregroundColor(setupManager.isDockerRunning ? .green : .red)
                    }

                    HStack {
                        Text("OpenMoxie Server")
                        Spacer()
                        Text(setupManager.isOpenMoxieRunning ? "Running" : "Stopped")
                            .foregroundColor(setupManager.isOpenMoxieRunning ? .green : .red)
                    }
                }

                Section("Server Controls") {
                    Button("Start OpenMoxie") {
                        Task { await setupManager.startOpenMoxie() }
                    }
                    .disabled(setupManager.isOpenMoxieRunning)

                    Button("Stop OpenMoxie") {
                        Task { await setupManager.stopOpenMoxie() }
                    }
                    .disabled(!setupManager.isOpenMoxieRunning)

                    Button("Restart OpenMoxie") {
                        Task { await setupManager.restartOpenMoxie() }
                    }
                    .disabled(!setupManager.isOpenMoxieRunning)
                }

                Section("Configuration") {
                    Button("Open Setup in Browser") {
                        setupManager.openSetupInBrowser()
                    }
                }
            }
            .formStyle(.grouped)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 400, height: 400)
        .padding()
    }
}

// MARK: - Documentation View

struct DocumentationView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Documentation")
                .font(.title)
                .fontWeight(.bold)

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    DocSection(title: "Getting Started", content: "Welcome to Moxie 2.0 Controller! This app lets you customize your Moxie robot's personality, appearance, and behavior.")

                    DocSection(title: "Custom Personalities", content: "Create unique personalities for Moxie by defining custom prompts, openers, and behavior settings.")

                    DocSection(title: "Appearance", content: "Change Moxie's face, eyes, hair, and other visual features to create a unique look.")

                    DocSection(title: "Conversations", content: "View and export conversations between Moxie and your child.")

                    DocSection(title: "Puppet Mode", content: "Take manual control of Moxie's expressions and movements.")

                    Button("Open Full Documentation") {
                        if let url = URL(string: "https://github.com/openmoxie/openmoxie") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                }
                .padding()
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 500, height: 500)
        .padding()
    }
}

struct DocSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            Text(content)
                .foregroundColor(.secondary)
        }
    }
}
