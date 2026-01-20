import Foundation
import AppKit

/// Service for checking Docker Desktop health status
class DockerHealthCheck {
    
    struct DockerStatus {
        let isHealthy: Bool
        let isInstalled: Bool
        let isRunning: Bool
        let containerRunning: Bool
        let userMessage: String
        
        static func healthy() -> DockerStatus {
            DockerStatus(
                isHealthy: true,
                isInstalled: true,
                isRunning: true,
                containerRunning: true,
                userMessage: "Docker is running correctly"
            )
        }
        
        static func notInstalled() -> DockerStatus {
            DockerStatus(
                isHealthy: false,
                isInstalled: false,
                isRunning: false,
                containerRunning: false,
                userMessage: "Docker Desktop is not installed. Please install it from docker.com"
            )
        }
        
        static func notRunning() -> DockerStatus {
            DockerStatus(
                isHealthy: false,
                isInstalled: true,
                isRunning: false,
                containerRunning: false,
                userMessage: "Docker Desktop is not running. Please start Docker Desktop."
            )
        }
        
        static func containerNotRunning() -> DockerStatus {
            DockerStatus(
                isHealthy: false,
                isInstalled: true,
                isRunning: true,
                containerRunning: false,
                userMessage: "OpenMoxie container is not running. Use the Setup Wizard to start it."
            )
        }
    }
    
    private let containerName = "openmoxie-server"
    private let mqttContainerName = "openmoxie-mqtt"

    /// Check Docker status synchronously
    func checkDockerStatus() -> DockerStatus {
        // Check if Docker is installed
        if !isDockerInstalled() {
            return .notInstalled()
        }

        // Check if Docker is running
        if !isDockerRunning() {
            return .notRunning()
        }

        // Check if OpenMoxie container is running
        if !isContainerRunning() {
            return .containerNotRunning()
        }

        return .healthy()
    }

    /// Check and automatically recover if possible
    func checkDockerStatusWithAutoRecovery() -> DockerStatus {
        // Check if Docker is installed
        if !isDockerInstalled() {
            return .notInstalled()
        }

        // Check if Docker is running, try to start if not
        if !isDockerRunning() {
            print("Docker not running, attempting to start...")
            if tryStartDocker() {
                // Wait a bit and check again
                Thread.sleep(forTimeInterval: 5)
                if !isDockerRunning() {
                    return .notRunning()
                }
            } else {
                return .notRunning()
            }
        }

        // Check if containers are running, try to start if not
        if !isContainerRunning() {
            print("Containers not running, attempting to start...")
            if tryStartContainers() {
                // Wait and check again
                Thread.sleep(forTimeInterval: 3)
                if isContainerRunning() {
                    return .healthy()
                }
            }
            return .containerNotRunning()
        }

        return .healthy()
    }

    /// Try to start Docker Desktop
    func tryStartDocker() -> Bool {
        // Try to open Docker Desktop
        if let dockerAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.docker.docker") {
            do {
                try NSWorkspace.shared.launchApplication(at: dockerAppURL, options: [], configuration: [:])
                print("Docker Desktop launch requested")
                return true
            } catch {
                print("Failed to launch Docker: \(error)")
            }
        }

        // Fallback to direct path
        let dockerAppPath = "/Applications/Docker.app"
        if FileManager.default.fileExists(atPath: dockerAppPath) {
            let result = runCommand("/usr/bin/open", arguments: ["-a", "Docker"])
            return result.success
        }

        return false
    }

    /// Try to start the OpenMoxie containers
    func tryStartContainers() -> Bool {
        // First try to start existing containers
        let startResult = runCommand("docker", arguments: ["start", containerName, mqttContainerName])
        if startResult.success {
            print("Containers started successfully")
            return true
        }

        // If that fails, try docker-compose in ~/OpenMoxie
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let composeFile = "\(homeDir)/OpenMoxie/docker-compose.yml"

        if FileManager.default.fileExists(atPath: composeFile) {
            let composeResult = runCommand("/bin/bash", arguments: ["-c", "cd ~/OpenMoxie && docker-compose up -d"])
            if composeResult.success {
                print("Containers started via docker-compose")
                return true
            }
        }

        return false
    }

    /// Wait for Docker to be ready (async version)
    func waitForDockerReady(timeout: TimeInterval = 30) -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if isDockerRunning() {
                return true
            }
            Thread.sleep(forTimeInterval: 1)
        }
        return false
    }

    /// Wait for containers to be ready
    func waitForContainersReady(timeout: TimeInterval = 30) -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if isContainerRunning() {
                return true
            }
            Thread.sleep(forTimeInterval: 1)
        }
        return false
    }
    
    private func isDockerInstalled() -> Bool {
        let dockerPaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker",
            "/Applications/Docker.app/Contents/Resources/bin/docker"
        ]
        
        let hasDockerApp = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.docker.docker") != nil
            || FileManager.default.fileExists(atPath: "/Applications/Docker.app")
        
        let hasDockerCLI = dockerPaths.contains { FileManager.default.fileExists(atPath: $0) }
        
        return hasDockerApp || hasDockerCLI
    }
    
    private func isDockerRunning() -> Bool {
        let result = runCommand("docker", arguments: ["info"])
        return result.success
    }
    
    private func isContainerRunning() -> Bool {
        let result = runCommand("docker", arguments: ["ps", "--filter", "name=\(containerName)", "--format", "{{.Names}}"])
        return result.output.contains(containerName)
    }
    
    private func runCommand(_ executable: String, arguments: [String]) -> (success: Bool, output: String) {
        let process = Process()
        
        // Find docker path
        let dockerPaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker"
        ]
        
        let dockerPath = dockerPaths.first { FileManager.default.fileExists(atPath: $0) } ?? "docker"
        
        if executable == "docker" {
            process.executableURL = URL(fileURLWithPath: dockerPath)
        } else {
            process.executableURL = URL(fileURLWithPath: executable)
        }
        
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return (process.terminationStatus == 0, output)
        } catch {
            return (false, "")
        }
    }
}
