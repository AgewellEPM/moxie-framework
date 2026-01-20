using System;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for controlling smart home devices via voice assistants
    /// (Alexa and Google Home integration through Moxie)
    /// </summary>
    public class SmartHomeService : ISmartHomeService
    {
        private readonly IMQTTService _mqttService;

        public SmartHomeService(IMQTTService mqttService)
        {
            _mqttService = mqttService;
        }

        public async Task SendVoiceCommandAsync(string command, VoiceAssistant assistant)
        {
            string prefix = assistant switch
            {
                VoiceAssistant.Alexa => "Alexa",
                VoiceAssistant.GoogleHome => "Hey Google",
                VoiceAssistant.Both => null, // Handle separately
                _ => null
            };

            if (assistant == VoiceAssistant.Both)
            {
                // Send to both assistants
                await SendVoiceCommandAsync(command, VoiceAssistant.Alexa);
                await Task.Delay(500); // Brief delay between commands
                await SendVoiceCommandAsync(command, VoiceAssistant.GoogleHome);
                return;
            }

            if (prefix == null)
            {
                return;
            }

            var speech = $"{prefix}, {command}";
            await _mqttService.SendCommandAsync("speak", speech);

            // Give assistant time to process
            await Task.Delay(500);

            Console.WriteLine($"🏠 Sent voice command: {speech}");
        }

        public async Task TurnOnDeviceAsync(string deviceName, VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync($"turn on {deviceName}", assistant);
        }

        public async Task TurnOffDeviceAsync(string deviceName, VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync($"turn off {deviceName}", assistant);
        }

        public async Task SetDeviceBrightnessAsync(string deviceName, int brightness, VoiceAssistant assistant)
        {
            if (brightness < 0 || brightness > 100)
            {
                throw new ArgumentOutOfRangeException(nameof(brightness), "Brightness must be between 0 and 100");
            }

            await SendVoiceCommandAsync($"set {deviceName} to {brightness} percent", assistant);
        }

        public async Task SetDeviceVolumeAsync(string deviceName, int volume, VoiceAssistant assistant)
        {
            if (volume < 0 || volume > 100)
            {
                throw new ArgumentOutOfRangeException(nameof(volume), "Volume must be between 0 and 100");
            }

            await SendVoiceCommandAsync($"set {deviceName} volume to {volume}", assistant);
        }

        public async Task SetTemperatureAsync(string deviceName, int temperature, VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync($"set {deviceName} to {temperature} degrees", assistant);
        }

        public async Task SetColorAsync(string deviceName, string color, VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync($"set {deviceName} to {color}", assistant);
        }

        public async Task PlayMusicAsync(string musicRequest, VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync($"play {musicRequest}", assistant);
        }

        public async Task StopMusicAsync(VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync("stop", assistant);
        }

        public async Task SetTimerAsync(int minutes, VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync($"set a timer for {minutes} minutes", assistant);
        }

        public async Task AskQuestionAsync(string question, VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync(question, assistant);
        }

        // MARK: - Smart Home Scenes

        public async Task ActivateSceneAsync(string sceneName, VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync($"turn on {sceneName}", assistant);
        }

        public async Task GoodMorningRoutineAsync(VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync("good morning", assistant);
        }

        public async Task GoodNightRoutineAsync(VoiceAssistant assistant)
        {
            await SendVoiceCommandAsync("good night", assistant);
        }

        // MARK: - Device Discovery (Placeholder)

        public Task<System.Collections.Generic.List<SmartHomeDevice>> DiscoverDevicesAsync()
        {
            // This would require platform-specific Bluetooth or network discovery
            // For now, return empty list
            Console.WriteLine("⚠️ Device discovery not yet implemented on Windows");
            return Task.FromResult(new System.Collections.Generic.List<SmartHomeDevice>());
        }
    }

    // MARK: - Voice Assistant Enum

    public enum VoiceAssistant
    {
        None,
        Alexa,
        GoogleHome,
        Both,
        Bluetooth
    }

    // MARK: - Interface

    public interface ISmartHomeService
    {
        Task SendVoiceCommandAsync(string command, VoiceAssistant assistant);
        Task TurnOnDeviceAsync(string deviceName, VoiceAssistant assistant);
        Task TurnOffDeviceAsync(string deviceName, VoiceAssistant assistant);
        Task SetDeviceBrightnessAsync(string deviceName, int brightness, VoiceAssistant assistant);
        Task SetDeviceVolumeAsync(string deviceName, int volume, VoiceAssistant assistant);
        Task SetTemperatureAsync(string deviceName, int temperature, VoiceAssistant assistant);
        Task SetColorAsync(string deviceName, string color, VoiceAssistant assistant);
        Task PlayMusicAsync(string musicRequest, VoiceAssistant assistant);
        Task StopMusicAsync(VoiceAssistant assistant);
        Task SetTimerAsync(int minutes, VoiceAssistant assistant);
        Task AskQuestionAsync(string question, VoiceAssistant assistant);
        Task ActivateSceneAsync(string sceneName, VoiceAssistant assistant);
        Task GoodMorningRoutineAsync(VoiceAssistant assistant);
        Task GoodNightRoutineAsync(VoiceAssistant assistant);
        Task<System.Collections.Generic.List<SmartHomeDevice>> DiscoverDevicesAsync();
    }
}
