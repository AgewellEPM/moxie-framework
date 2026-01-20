using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;

namespace SimpleMoxieSwitcher.ViewModels
{
    /// <summary>
    /// ViewModel for managing and controlling smart home devices via Alexa/Google Home
    /// </summary>
    public class SmartHomeViewModel : INotifyPropertyChanged
    {
        private ObservableCollection<SmartHomeDevice> _devices = new();
        private bool _isLoading;
        private bool _isScanning;
        private string? _statusMessage;
        private bool _showAddDevice;

        private readonly SmartHomeService _smartHomeService;
        private const string DevicesKey = "smart_home_devices";

        public SmartHomeViewModel(SmartHomeService smartHomeService)
        {
            _smartHomeService = smartHomeService;
            LoadDevices();
        }

        #region Properties

        public ObservableCollection<SmartHomeDevice> Devices
        {
            get => _devices;
            set => SetProperty(ref _devices, value);
        }

        public bool IsLoading
        {
            get => _isLoading;
            set => SetProperty(ref _isLoading, value);
        }

        public bool IsScanning
        {
            get => _isScanning;
            set => SetProperty(ref _isScanning, value);
        }

        public string? StatusMessage
        {
            get => _statusMessage;
            set => SetProperty(ref _statusMessage, value);
        }

        public bool ShowAddDevice
        {
            get => _showAddDevice;
            set => SetProperty(ref _showAddDevice, value);
        }

        #endregion

        #region Methods

        public async Task ScanForBluetoothDevicesAsync()
        {
            IsScanning = true;
            StatusMessage = "🔍 Scanning for Bluetooth devices...";

            try
            {
                var discoveredDevices = await _smartHomeService.ScanForBluetoothDevicesAsync();

                // Add new devices that aren't already in the list
                foreach (var device in discoveredDevices)
                {
                    if (!Devices.Any(d => d.BluetoothID == device.BluetoothID))
                    {
                        Devices.Add(device);
                    }
                }

                SaveDevices();
                StatusMessage = $"✓ Found {discoveredDevices.Count} Bluetooth device(s)";

                await Task.Delay(3000);
                StatusMessage = null;
            }
            catch (Exception ex)
            {
                StatusMessage = "✗ Failed to scan for Bluetooth devices";
                Console.WriteLine($"Bluetooth scan error: {ex.Message}");
            }

            IsScanning = false;
        }

        public void LoadDevices()
        {
            try
            {
                var json = Properties.Settings.Default.SmartHomeDevices;
                if (!string.IsNullOrEmpty(json))
                {
                    var devices = JsonSerializer.Deserialize<List<SmartHomeDevice>>(json);
                    if (devices != null)
                    {
                        Devices = new ObservableCollection<SmartHomeDevice>(devices);
                        return;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading devices: {ex.Message}");
            }

            // Load sample devices if no saved devices
            Devices = new ObservableCollection<SmartHomeDevice>(SmartHomeDevice.GetSampleDevices());
            SaveDevices();
        }

        public void SaveDevices()
        {
            try
            {
                var json = JsonSerializer.Serialize(Devices.ToList());
                Properties.Settings.Default.SmartHomeDevices = json;
                Properties.Settings.Default.Save();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error saving devices: {ex.Message}");
            }
        }

        public async Task ToggleDeviceAsync(SmartHomeDevice device)
        {
            var deviceToUpdate = Devices.FirstOrDefault(d => d.Id == device.Id);
            if (deviceToUpdate == null)
                return;

            IsLoading = true;

            try
            {
                if (deviceToUpdate.IsOn)
                {
                    await _smartHomeService.TurnOffDeviceAsync(deviceToUpdate.VoiceCommandName, deviceToUpdate.VoiceAssistant);
                    deviceToUpdate.IsOn = false;
                    StatusMessage = $"✓ Turned off {deviceToUpdate.Name}";
                }
                else
                {
                    await _smartHomeService.TurnOnDeviceAsync(deviceToUpdate.VoiceCommandName, deviceToUpdate.VoiceAssistant);
                    deviceToUpdate.IsOn = true;
                    StatusMessage = $"✓ Turned on {deviceToUpdate.Name}";
                }

                SaveDevices();

                // Clear status after 3 seconds
                await Task.Delay(3000);
                StatusMessage = null;
            }
            catch (Exception ex)
            {
                StatusMessage = $"✗ Failed to control {deviceToUpdate.Name}";
                Console.WriteLine($"Error toggling device: {ex.Message}");
            }

            IsLoading = false;
        }

        public async Task SetBrightnessAsync(SmartHomeDevice device, int brightness)
        {
            var deviceToUpdate = Devices.FirstOrDefault(d => d.Id == device.Id);
            if (deviceToUpdate == null)
                return;

            try
            {
                await _smartHomeService.SetDeviceBrightnessAsync(deviceToUpdate.VoiceCommandName, brightness, deviceToUpdate.VoiceAssistant);
                deviceToUpdate.Brightness = brightness;
                SaveDevices();
                StatusMessage = $"✓ Set {deviceToUpdate.Name} brightness to {brightness}%";

                await Task.Delay(2000);
                StatusMessage = null;
            }
            catch (Exception ex)
            {
                StatusMessage = "✗ Failed to set brightness";
                Console.WriteLine($"Error setting brightness: {ex.Message}");
            }
        }

        public async Task SetVolumeAsync(SmartHomeDevice device, int volume)
        {
            var deviceToUpdate = Devices.FirstOrDefault(d => d.Id == device.Id);
            if (deviceToUpdate == null)
                return;

            try
            {
                await _smartHomeService.SetDeviceVolumeAsync(deviceToUpdate.VoiceCommandName, volume, deviceToUpdate.VoiceAssistant);
                deviceToUpdate.Volume = volume;
                SaveDevices();
                StatusMessage = $"✓ Set {deviceToUpdate.Name} volume to {volume}";

                await Task.Delay(2000);
                StatusMessage = null;
            }
            catch (Exception ex)
            {
                StatusMessage = "✗ Failed to set volume";
                Console.WriteLine($"Error setting volume: {ex.Message}");
            }
        }

        public async Task SetTemperatureAsync(SmartHomeDevice device, int temperature)
        {
            var deviceToUpdate = Devices.FirstOrDefault(d => d.Id == device.Id);
            if (deviceToUpdate == null)
                return;

            try
            {
                await _smartHomeService.SetTemperatureAsync(deviceToUpdate.VoiceCommandName, temperature, deviceToUpdate.VoiceAssistant);
                deviceToUpdate.Temperature = temperature;
                SaveDevices();
                StatusMessage = $"✓ Set {deviceToUpdate.Name} to {temperature}°";

                await Task.Delay(2000);
                StatusMessage = null;
            }
            catch (Exception ex)
            {
                StatusMessage = "✗ Failed to set temperature";
                Console.WriteLine($"Error setting temperature: {ex.Message}");
            }
        }

        public void AddDevice(SmartHomeDevice device)
        {
            Devices.Add(device);
            SaveDevices();
        }

        public void DeleteDevice(SmartHomeDevice device)
        {
            var deviceToRemove = Devices.FirstOrDefault(d => d.Id == device.Id);
            if (deviceToRemove != null)
            {
                Devices.Remove(deviceToRemove);
                SaveDevices();
            }
        }

        public async Task SendCustomCommandAsync(string command, VoiceAssistant assistant = VoiceAssistant.Alexa)
        {
            IsLoading = true;

            try
            {
                await _smartHomeService.SendVoiceCommandAsync(command, assistant);
                StatusMessage = $"✓ Sent command: {command}";

                await Task.Delay(2000);
                StatusMessage = null;
            }
            catch (Exception ex)
            {
                StatusMessage = "✗ Failed to send command";
                Console.WriteLine($"Error sending command: {ex.Message}");
            }

            IsLoading = false;
        }

        #endregion

        #region INotifyPropertyChanged

        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        protected bool SetProperty<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
        {
            if (EqualityComparer<T>.Default.Equals(field, value))
                return false;

            field = value;
            OnPropertyChanged(propertyName);
            return true;
        }

        #endregion
    }
}
