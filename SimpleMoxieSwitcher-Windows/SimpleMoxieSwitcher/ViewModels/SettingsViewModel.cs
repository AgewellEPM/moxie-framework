using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Services;

namespace SimpleMoxieSwitcher.ViewModels
{
    /// <summary>
    /// ViewModel for application settings
    /// </summary>
    public class SettingsViewModel : INotifyPropertyChanged
    {
        private bool _isResetting;
        private string? _moxieEndpoint;
        private string? _mqttBroker;
        private string? _mqttTopic;
        private bool _enableNotifications;
        private bool _enableSafetyMonitoring;
        private bool _enableMemoryExtraction;

        private readonly IPersonalityService _personalityService;

        public SettingsViewModel(IPersonalityService personalityService)
        {
            _personalityService = personalityService;
            LoadSettings();
        }

        #region Properties

        public bool IsResetting
        {
            get => _isResetting;
            set => SetProperty(ref _isResetting, value);
        }

        public string? MoxieEndpoint
        {
            get => _moxieEndpoint;
            set
            {
                if (SetProperty(ref _moxieEndpoint, value))
                {
                    Properties.Settings.Default.MoxieEndpoint = value;
                    Properties.Settings.Default.Save();
                }
            }
        }

        public string? MqttBroker
        {
            get => _mqttBroker;
            set
            {
                if (SetProperty(ref _mqttBroker, value))
                {
                    Properties.Settings.Default.MqttBroker = value;
                    Properties.Settings.Default.Save();
                }
            }
        }

        public string? MqttTopic
        {
            get => _mqttTopic;
            set
            {
                if (SetProperty(ref _mqttTopic, value))
                {
                    Properties.Settings.Default.MqttTopic = value;
                    Properties.Settings.Default.Save();
                }
            }
        }

        public bool EnableNotifications
        {
            get => _enableNotifications;
            set
            {
                if (SetProperty(ref _enableNotifications, value))
                {
                    Properties.Settings.Default.EnableNotifications = value;
                    Properties.Settings.Default.Save();
                }
            }
        }

        public bool EnableSafetyMonitoring
        {
            get => _enableSafetyMonitoring;
            set
            {
                if (SetProperty(ref _enableSafetyMonitoring, value))
                {
                    Properties.Settings.Default.EnableSafetyMonitoring = value;
                    Properties.Settings.Default.Save();
                }
            }
        }

        public bool EnableMemoryExtraction
        {
            get => _enableMemoryExtraction;
            set
            {
                if (SetProperty(ref _enableMemoryExtraction, value))
                {
                    Properties.Settings.Default.EnableMemoryExtraction = value;
                    Properties.Settings.Default.Save();
                }
            }
        }

        #endregion

        #region Methods

        private void LoadSettings()
        {
            _moxieEndpoint = Properties.Settings.Default.MoxieEndpoint;
            _mqttBroker = Properties.Settings.Default.MqttBroker;
            _mqttTopic = Properties.Settings.Default.MqttTopic;
            _enableNotifications = Properties.Settings.Default.EnableNotifications;
            _enableSafetyMonitoring = Properties.Settings.Default.EnableSafetyMonitoring;
            _enableMemoryExtraction = Properties.Settings.Default.EnableMemoryExtraction;

            // Notify all properties
            OnPropertyChanged(nameof(MoxieEndpoint));
            OnPropertyChanged(nameof(MqttBroker));
            OnPropertyChanged(nameof(MqttTopic));
            OnPropertyChanged(nameof(EnableNotifications));
            OnPropertyChanged(nameof(EnableSafetyMonitoring));
            OnPropertyChanged(nameof(EnableMemoryExtraction));
        }

        public async Task ResetPersonalitiesAsync()
        {
            IsResetting = true;
            try
            {
                // Reset to default personalities
                // In production, this would call personality repository
                await Task.Delay(500); // Simulate async operation
            }
            finally
            {
                IsResetting = false;
            }
        }

        public void ResetToDefaults()
        {
            MoxieEndpoint = "http://localhost:8003/hive/endpoint/";
            MqttBroker = "localhost:1883";
            MqttTopic = "openmoxie/chat";
            EnableNotifications = true;
            EnableSafetyMonitoring = true;
            EnableMemoryExtraction = true;
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
