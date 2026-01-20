using Docker.DotNet;
using Docker.DotNet.Models;
using SimpleMoxieSwitcher.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace SimpleMoxieSwitcher.Services;

public class DockerService : IDockerService
{
    private readonly string _containerName = "openmoxie-server";
    private readonly DockerClient _dockerClient;
    private string? _dockerPath;

    public DockerService()
    {
        // Connect to Docker on Windows
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            _dockerClient = new DockerClientConfiguration(
                new Uri("npipe://./pipe/docker_engine"))
                .CreateClient();
        }
        else
        {
            _dockerClient = new DockerClientConfiguration(
                new Uri("unix:///var/run/docker.sock"))
                .CreateClient();
        }

        _dockerPath = FindDockerPath();
    }

    private string? FindDockerPath()
    {
        // Try common Docker locations on Windows
        var possiblePaths = new[]
        {
            @"C:\Program Files\Docker\Docker\resources\bin\docker.exe",
            @"C:\Program Files\Docker\Docker\docker.exe",
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Docker\Docker\resources\bin\docker.exe")
        };

        foreach (var path in possiblePaths)
        {
            if (File.Exists(path))
            {
                return path;
            }
        }

        // Try to find docker in PATH
        var pathEnv = Environment.GetEnvironmentVariable("PATH");
        if (!string.IsNullOrEmpty(pathEnv))
        {
            var paths = pathEnv.Split(Path.PathSeparator);
            foreach (var path in paths)
            {
                var dockerPath = Path.Combine(path, "docker.exe");
                if (File.Exists(dockerPath))
                {
                    return dockerPath;
                }
            }
        }

        // Fallback to just "docker" and hope it's in PATH
        return "docker";
    }

    public async Task<bool> IsDockerRunningAsync()
    {
        try
        {
            await _dockerClient.System.PingAsync();
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> IsContainerRunningAsync()
    {
        try
        {
            var containers = await _dockerClient.Containers.ListContainersAsync(
                new ContainersListParameters
                {
                    All = true
                });

            var container = containers.FirstOrDefault(c =>
                c.Names.Any(n => n.Contains(_containerName)));

            return container?.State == "running";
        }
        catch
        {
            return false;
        }
    }

    public async Task StartContainerAsync()
    {
        try
        {
            // Check if container exists
            var containers = await _dockerClient.Containers.ListContainersAsync(
                new ContainersListParameters
                {
                    All = true
                });

            var container = containers.FirstOrDefault(c =>
                c.Names.Any(n => n.Contains(_containerName)));

            if (container != null)
            {
                // Start existing container
                await _dockerClient.Containers.StartContainerAsync(
                    container.ID,
                    new ContainerStartParameters());
            }
            else
            {
                // Create and start new container
                await CreateAndStartContainerAsync();
            }
        }
        catch (Exception ex)
        {
            // Fallback to command line
            await ExecuteDockerCommandAsync($"start {_containerName}");
        }
    }

    private async Task CreateAndStartContainerAsync()
    {
        // Pull image if not exists
        await _dockerClient.Images.CreateImageAsync(
            new ImagesCreateParameters
            {
                FromImage = "openmoxie/openmoxie-server",
                Tag = "latest"
            },
            null,
            new Progress<JSONMessage>());

        // Create container
        var response = await _dockerClient.Containers.CreateContainerAsync(
            new CreateContainerParameters
            {
                Name = _containerName,
                Image = "openmoxie/openmoxie-server:latest",
                ExposedPorts = new Dictionary<string, EmptyStruct>
                {
                    ["8003/tcp"] = default
                },
                HostConfig = new HostConfig
                {
                    PortBindings = new Dictionary<string, IList<PortBinding>>
                    {
                        ["8003/tcp"] = new List<PortBinding>
                        {
                            new PortBinding { HostPort = "8003" }
                        }
                    },
                    Binds = new List<string>
                    {
                        $"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}/.openmoxie:/app/data"
                    },
                    RestartPolicy = new RestartPolicy
                    {
                        Name = RestartPolicyKind.UnlessStopped
                    }
                }
            });

        // Start container
        await _dockerClient.Containers.StartContainerAsync(
            response.ID,
            new ContainerStartParameters());
    }

    public async Task StopContainerAsync()
    {
        try
        {
            var containers = await _dockerClient.Containers.ListContainersAsync(
                new ContainersListParameters
                {
                    All = true
                });

            var container = containers.FirstOrDefault(c =>
                c.Names.Any(n => n.Contains(_containerName)));

            if (container != null)
            {
                await _dockerClient.Containers.StopContainerAsync(
                    container.ID,
                    new ContainerStopParameters
                    {
                        WaitBeforeKillSeconds = 10
                    });
            }
        }
        catch
        {
            // Fallback to command line
            await ExecuteDockerCommandAsync($"stop {_containerName}");
        }
    }

    public async Task RestartServerAsync()
    {
        try
        {
            var containers = await _dockerClient.Containers.ListContainersAsync(
                new ContainersListParameters
                {
                    All = true
                });

            var container = containers.FirstOrDefault(c =>
                c.Names.Any(n => n.Contains(_containerName)));

            if (container != null)
            {
                await _dockerClient.Containers.RestartContainerAsync(
                    container.ID,
                    new ContainerRestartParameters
                    {
                        WaitBeforeKillSeconds = 10
                    });
            }

            // Wait for container to be ready
            await Task.Delay(5000);
        }
        catch
        {
            // Fallback to command line
            await ExecuteDockerCommandAsync($"restart {_containerName}");
            await Task.Delay(5000);
        }
    }

    public async Task<string> ExecutePythonScriptAsync(string script)
    {
        // Escape the script for command line
        var escapedScript = script.Replace("\"", "\\\"").Replace("\n", " ");

        var command = $"exec -w /app/site {_containerName} python3 manage.py shell -c \"{escapedScript}\"";
        return await ExecuteDockerCommandAsync(command);
    }

    private async Task<string> ExecuteDockerCommandAsync(string arguments)
    {
        if (string.IsNullOrEmpty(_dockerPath))
        {
            throw new InvalidOperationException("Docker not found. Please install Docker Desktop for Windows.");
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = _dockerPath,
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

        if (process.ExitCode != 0)
        {
            var errorMessage = error.ToString();
            if (string.IsNullOrEmpty(errorMessage))
            {
                errorMessage = output.ToString();
            }
            throw new DockerException($"Docker command failed: {errorMessage}");
        }

        return output.ToString();
    }
}

public class DockerException : Exception
{
    public DockerException(string message) : base(message)
    {
    }
}