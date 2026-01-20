import Foundation

final class DockerService: DockerServiceProtocol {
    private let containerName = "openmoxie-server"

    private var dockerPath: String {
        // Try multiple common Docker locations
        let possiblePaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker",
            "/Applications/Docker.app/Contents/Resources/bin/docker"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // If not found, try using 'which' command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "which docker"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {
            print("Failed to find docker with 'which': \(error)")
        }

        // Default fallback
        return "docker"
    }

    func executePythonScript(_ script: String) async throws -> String {
        let escapedScript = script.replacingOccurrences(of: "\"", with: "\\\"")
        let dockerCommand = "\(dockerPath) exec -w /app/site \(containerName) python3 manage.py shell -c \"\(escapedScript)\""

        print("[DockerService] Using docker at: \(dockerPath)")
        print("[DockerService] Executing command...")

        do {
            let result = try await executeCommand(dockerCommand)
            print("[DockerService] Success: \(result)")
            return result
        } catch {
            print("[DockerService] Error: \(error)")
            throw error
        }
    }

    func restartServer() async throws {
        let restartCommand = "\(dockerPath) restart \(containerName) && sleep 5"
        _ = try await executeCommand(restartCommand)
    }

    private func executeCommand(_ command: String) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw DockerError.executionFailed(errorMessage)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

enum DockerError: LocalizedError {
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .executionFailed(let message):
            return "Docker command failed: \(message)"
        }
    }
}