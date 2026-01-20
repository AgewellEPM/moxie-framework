import Foundation

/// Service to check Docker installation and health status
final class DockerHealthCheck {
    enum DockerStatus {
        case installed(isRunning: Bool)
        case notInstalled
        case unknown(error: String)

        var isHealthy: Bool {
            if case .installed(let isRunning) = self, isRunning {
                return true
            }
            return false
        }

        var userMessage: String {
            switch self {
            case .installed(let isRunning):
                if isRunning {
                    return "Docker is installed and running"
                } else {
                    return "Docker is installed but not running.\n\nPlease start Docker Desktop and try again."
                }
            case .notInstalled:
                return """
                Docker Desktop is not installed.

                SimpleMoxieSwitcher requires Docker Desktop to run the OpenMoxie backend.

                To install Docker Desktop:
                1. Visit https://www.docker.com/products/docker-desktop
                2. Download Docker Desktop for Mac
                3. Install and start Docker Desktop
                4. Restart SimpleMoxieSwitcher
                """
            case .unknown(let error):
                return "Could not determine Docker status: \(error)"
            }
        }
    }

    private var dockerPath: String? {
        let possiblePaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Try using 'which' command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "which docker"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            print("Failed to find docker with 'which': \(error)")
        }

        return nil
    }

    /// Check if Docker is installed and running
    func checkDockerStatus() -> DockerStatus {
        guard let dockerPath = dockerPath else {
            return .notInstalled
        }

        // Check if Docker daemon is running by trying to execute 'docker ps'
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "\(dockerPath) ps"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                return .installed(isRunning: true)
            } else {
                // Docker is installed but not running
                return .installed(isRunning: false)
            }
        } catch {
            return .unknown(error: error.localizedDescription)
        }
    }

    /// Check if the OpenMoxie container is running
    func checkOpenMoxieContainer() -> Bool {
        guard let dockerPath = dockerPath else {
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "\(dockerPath) ps --filter name=openmoxie-server --format '{{.Names}}'"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return output.contains("openmoxie-server")
            }
        } catch {
            print("Failed to check OpenMoxie container: \(error)")
        }

        return false
    }
}
