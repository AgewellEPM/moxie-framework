using SimpleMoxieSwitcher.Services.Interfaces;
using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace SimpleMoxieSwitcher.Services;

public class DependencyInstallationService : IDependencyInstallationService
{
    private readonly HttpClient _httpClient = new();

    public bool IsInstalling { get; private set; }
    public string InstallationProgress { get; private set; } = string.Empty;
    public string? InstallationError { get; private set; }

    public event EventHandler<string>? ProgressChanged;
    public event EventHandler<string>? ErrorOccurred;
    public event EventHandler? InstallationCompleted;

    public async Task<bool> CheckDockerInstalledAsync()
    {
        try
        {
            // Check if Docker Desktop is installed on Windows
            var dockerPaths = new[]
            {
                @"C:\Program Files\Docker\Docker\Docker Desktop.exe",
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Docker\Docker\Docker Desktop.exe")
            };

            foreach (var path in dockerPaths)
            {
                if (File.Exists(path))
                {
                    return true;
                }
            }

            // Try to run docker version command
            var result = await RunCommandAsync("docker", "version");
            return result.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> CheckMosquittoInstalledAsync()
    {
        try
        {
            // Check if Mosquitto is installed
            var mosquittoPaths = new[]
            {
                @"C:\Program Files\mosquitto\mosquitto.exe",
                @"C:\Program Files (x86)\mosquitto\mosquitto.exe",
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"mosquitto\mosquitto.exe")
            };

            foreach (var path in mosquittoPaths)
            {
                if (File.Exists(path))
                {
                    return true;
                }
            }

            // Check if mosquitto service exists
            var result = await RunCommandAsync("sc", "query mosquitto");
            return result.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }

    public async Task InstallDockerAsync()
    {
        IsInstalling = true;
        InstallationError = null;

        try
        {
            UpdateProgress("Downloading Docker Desktop for Windows...");

            // Download Docker Desktop installer
            var installerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe";
            var installerPath = Path.Combine(Path.GetTempPath(), "DockerDesktopInstaller.exe");

            await DownloadFileAsync(installerUrl, installerPath);

            UpdateProgress("Installing Docker Desktop... This may take a few minutes.");

            // Run the installer silently
            var result = await RunCommandAsync(installerPath, "install --quiet --accept-license");

            if (result.ExitCode != 0)
            {
                throw new Exception($"Docker installation failed: {result.StandardError}");
            }

            UpdateProgress("Docker Desktop installed successfully!");

            // Clean up installer
            File.Delete(installerPath);
        }
        catch (Exception ex)
        {
            InstallationError = ex.Message;
            ErrorOccurred?.Invoke(this, ex.Message);
        }
        finally
        {
            IsInstalling = false;
            InstallationCompleted?.Invoke(this, EventArgs.Empty);
        }
    }

    public async Task InstallMosquittoAsync()
    {
        IsInstalling = true;
        InstallationError = null;

        try
        {
            UpdateProgress("Downloading Mosquitto MQTT broker...");

            // Download Mosquitto installer
            var installerUrl = "https://mosquitto.org/files/binary/win64/mosquitto-2.0.18-install-windows-x64.exe";
            var installerPath = Path.Combine(Path.GetTempPath(), "mosquitto-installer.exe");

            await DownloadFileAsync(installerUrl, installerPath);

            UpdateProgress("Installing Mosquitto MQTT broker...");

            // Run the installer silently
            var result = await RunCommandAsync(installerPath, "/S");

            if (result.ExitCode != 0)
            {
                throw new Exception($"Mosquitto installation failed: {result.StandardError}");
            }

            UpdateProgress("Configuring Mosquitto for OpenMoxie...");
            await ConfigureMosquittoAsync();

            UpdateProgress("Starting Mosquitto service...");
            await StartMosquittoServiceAsync();

            UpdateProgress("Mosquitto installed and configured successfully!");

            // Clean up installer
            File.Delete(installerPath);
        }
        catch (Exception ex)
        {
            InstallationError = ex.Message;
            ErrorOccurred?.Invoke(this, ex.Message);
        }
        finally
        {
            IsInstalling = false;
            InstallationCompleted?.Invoke(this, EventArgs.Empty);
        }
    }

    private async Task ConfigureMosquittoAsync()
    {
        // Find Mosquitto installation directory
        var mosquittoDir = @"C:\Program Files\mosquitto";
        if (!Directory.Exists(mosquittoDir))
        {
            mosquittoDir = @"C:\Program Files (x86)\mosquitto";
        }

        if (!Directory.Exists(mosquittoDir))
        {
            throw new Exception("Mosquitto installation directory not found");
        }

        // Create mosquitto.conf for OpenMoxie
        var configPath = Path.Combine(mosquittoDir, "mosquitto.conf");
        var config = @"# Mosquitto configuration for OpenMoxie
listener 1883
protocol mqtt

listener 8883
protocol mqtt
require_certificate false
allow_anonymous true

# WebSocket support
listener 9001
protocol websockets

# Persistence
persistence true
persistence_location C:\ProgramData\mosquitto\

# Logging
log_dest file C:\ProgramData\mosquitto\mosquitto.log
log_type all

# Security
allow_anonymous true
";

        await File.WriteAllTextAsync(configPath, config);

        // Create data directory
        var dataDir = @"C:\ProgramData\mosquitto";
        if (!Directory.Exists(dataDir))
        {
            Directory.CreateDirectory(dataDir);
        }
    }

    private async Task StartMosquittoServiceAsync()
    {
        // Stop service if running
        await RunCommandAsync("net", "stop mosquitto");

        // Start service
        var result = await RunCommandAsync("net", "start mosquitto");

        if (result.ExitCode != 0)
        {
            // Try to install and start as a service
            var mosquittoPath = @"C:\Program Files\mosquitto\mosquitto.exe";
            if (!File.Exists(mosquittoPath))
            {
                mosquittoPath = @"C:\Program Files (x86)\mosquitto\mosquitto.exe";
            }

            if (File.Exists(mosquittoPath))
            {
                // Install as service
                await RunCommandAsync(mosquittoPath, "-install");

                // Start service
                await RunCommandAsync("net", "start mosquitto");
            }
        }
    }

    public async Task SetupOpenMoxieContainerAsync()
    {
        IsInstalling = true;
        InstallationError = null;

        try
        {
            UpdateProgress("Looking for bundled OpenMoxie...");

            // Get the path to bundled OpenMoxie (next to the application executable)
            var appPath = AppDomain.CurrentDomain.BaseDirectory;
            var bundledOpenMoxie = Path.Combine(appPath, "OpenMoxie");

            if (!Directory.Exists(bundledOpenMoxie))
            {
                throw new Exception("OpenMoxie backend not found. Please ensure the OpenMoxie folder is in the same directory as SimpleMoxieSwitcher.exe");
            }

            // Copy OpenMoxie to user's profile for Docker access
            var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            var openmoxieDir = Path.Combine(userProfile, "OpenMoxie");

            // Remove existing directory if it exists
            if (Directory.Exists(openmoxieDir))
            {
                UpdateProgress("Removing old OpenMoxie installation...");
                Directory.Delete(openmoxieDir, recursive: true);
            }

            // Copy bundled OpenMoxie to user profile
            UpdateProgress("Installing OpenMoxie...");
            CopyDirectory(bundledOpenMoxie, openmoxieDir);

            // Check if docker-compose exists
            UpdateProgress("Building OpenMoxie Docker image...");
            var dockerComposePath = Path.Combine(openmoxieDir, "docker-compose.yml");
            if (!File.Exists(dockerComposePath))
            {
                throw new Exception("docker-compose.yml not found in OpenMoxie directory");
            }

            // Build with docker-compose
            var buildResult = await RunCommandAsync("docker-compose", $"-f \"{dockerComposePath}\" build");
            if (buildResult.ExitCode != 0)
            {
                throw new Exception($"Failed to build OpenMoxie image: {buildResult.StandardError}");
            }

            // Start containers
            UpdateProgress("Starting OpenMoxie containers...");
            var upResult = await RunCommandAsync("docker-compose", $"-f \"{dockerComposePath}\" up -d");
            if (upResult.ExitCode != 0)
            {
                throw new Exception($"Failed to start OpenMoxie containers: {upResult.StandardError}");
            }

            // Run migrations
            UpdateProgress("Running database migrations...");
            var migrateResult = await RunCommandAsync("docker-compose", $"-f \"{dockerComposePath}\" exec -T web python manage.py migrate");

            // Create superuser if needed
            UpdateProgress("Setting up admin user...");
            var superuserCommand = "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@example.com', 'admin')";
            await RunCommandAsync("docker-compose", $"-f \"{dockerComposePath}\" exec -T web python manage.py shell -c \"{superuserCommand}\"");

            UpdateProgress("OpenMoxie installed and running!");
        }
        catch (Exception ex)
        {
            InstallationError = ex.Message;
            ErrorOccurred?.Invoke(this, ex.Message);
        }
        finally
        {
            IsInstalling = false;
            InstallationCompleted?.Invoke(this, EventArgs.Empty);
        }
    }

    private void CopyDirectory(string sourceDir, string destDir)
    {
        // Create destination directory
        Directory.CreateDirectory(destDir);

        // Copy all files
        foreach (var file in Directory.GetFiles(sourceDir))
        {
            var fileName = Path.GetFileName(file);
            var destFile = Path.Combine(destDir, fileName);
            File.Copy(file, destFile, overwrite: true);
        }

        // Copy all subdirectories recursively
        foreach (var directory in Directory.GetDirectories(sourceDir))
        {
            var dirName = Path.GetFileName(directory);
            var destSubDir = Path.Combine(destDir, dirName);
            CopyDirectory(directory, destSubDir);
        }
    }

    public async Task RunCompleteSetupAsync()
    {
        IsInstalling = true;
        InstallationError = null;

        try
        {
            // Check and install Docker if needed
            if (!await CheckDockerInstalledAsync())
            {
                UpdateProgress("Docker not found. Please install Docker Desktop manually.");
                InstallationError = "Docker Desktop needs to be installed manually. Please download it from https://www.docker.com/products/docker-desktop/";
                return;
            }

            UpdateProgress("Docker is installed ✓");

            // Check and install Mosquitto if needed
            if (!await CheckMosquittoInstalledAsync())
            {
                await InstallMosquittoAsync();
            }
            else
            {
                UpdateProgress("Mosquitto is already installed ✓");
                await StartMosquittoServiceAsync();
            }

            // Setup OpenMoxie container
            await SetupOpenMoxieContainerAsync();

            UpdateProgress("✅ All dependencies installed successfully!");
        }
        catch (Exception ex)
        {
            InstallationError = $"Setup failed: {ex.Message}";
            ErrorOccurred?.Invoke(this, ex.Message);
        }
        finally
        {
            IsInstalling = false;
            InstallationCompleted?.Invoke(this, EventArgs.Empty);
        }
    }

    private async Task DownloadFileAsync(string url, string destinationPath)
    {
        using var response = await _httpClient.GetAsync(url, HttpCompletionOption.ResponseHeadersRead);
        response.EnsureSuccessStatusCode();

        using var fileStream = new FileStream(destinationPath, FileMode.Create, FileAccess.Write, FileShare.None);
        await response.Content.CopyToAsync(fileStream);
    }

    private async Task<ProcessResult> RunCommandAsync(string fileName, string arguments)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };

        using var process = new Process { StartInfo = startInfo };
        var output = new StringBuilder();
        var error = new StringBuilder();

        process.OutputDataReceived += (sender, e) =>
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                output.AppendLine(e.Data);
            }
        };

        process.ErrorDataReceived += (sender, e) =>
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                error.AppendLine(e.Data);
            }
        };

        process.Start();
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();

        await process.WaitForExitAsync();

        return new ProcessResult
        {
            ExitCode = process.ExitCode,
            StandardOutput = output.ToString(),
            StandardError = error.ToString()
        };
    }

    private void UpdateProgress(string message)
    {
        InstallationProgress = message;
        ProgressChanged?.Invoke(this, message);
    }

    private class ProcessResult
    {
        public int ExitCode { get; set; }
        public string StandardOutput { get; set; } = string.Empty;
        public string StandardError { get; set; } = string.Empty;
    }
}