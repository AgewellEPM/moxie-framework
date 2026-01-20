import Foundation
@testable import SimpleMoxieSwitcher

final class MockMQTTService: MQTTServiceProtocol {
    // Tracking properties
    var connectCalled = false
    var disconnectCalled = false
    var sendCommandCalled = false
    var publishCalled = false

    // Captured values
    var lastCommand: String?
    var lastSpeech: String?
    var lastTopic: String?
    var lastMessage: String?

    // Mock responses
    var shouldFailConnection = false

    func connect() {
        connectCalled = true
    }

    func disconnect() {
        disconnectCalled = true
    }

    func sendCommand(_ command: String, speech: String) {
        sendCommandCalled = true
        lastCommand = command
        lastSpeech = speech
    }

    func publish(topic: String, message: String) {
        publishCalled = true
        lastTopic = topic
        lastMessage = message
    }

    // Reset method for test cleanup
    func reset() {
        connectCalled = false
        disconnectCalled = false
        sendCommandCalled = false
        publishCalled = false
        lastCommand = nil
        lastSpeech = nil
        lastTopic = nil
        lastMessage = nil
        shouldFailConnection = false
    }
}

final class MockDockerService: DockerServiceProtocol {
    var executePythonScriptCalled = false
    var restartServerCalled = false
    var lastScript: String?

    var mockResponse = "Success"
    var shouldThrowError = false

    func executePythonScript(_ script: String) async throws -> String {
        executePythonScriptCalled = true
        lastScript = script

        if shouldThrowError {
            throw MockError.testError
        }

        return mockResponse
    }

    func restartServer() async throws {
        restartServerCalled = true

        if shouldThrowError {
            throw MockError.testError
        }
    }

    func reset() {
        executePythonScriptCalled = false
        restartServerCalled = false
        lastScript = nil
        mockResponse = "Success"
        shouldThrowError = false
    }
}

enum MockError: Error {
    case testError
}