using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;

namespace SimpleMoxieSwitcher.ViewModels
{
    /// <summary>
    /// ViewModel for controlling Moxie robot movements, audio, camera, and emotions
    /// </summary>
    public class ControlsViewModel : INotifyPropertyChanged
    {
        private bool _cameraEnabled;
        private double _volume = 50;
        private bool _isMuted;
        private string? _statusMessage;
        private bool _isLoading;

        private readonly IMQTTService _mqttService;

        public ControlsViewModel(IMQTTService mqttService)
        {
            _mqttService = mqttService;
        }

        #region Properties

        public bool CameraEnabled
        {
            get => _cameraEnabled;
            set => SetProperty(ref _cameraEnabled, value);
        }

        public double Volume
        {
            get => _volume;
            set => SetProperty(ref _volume, value);
        }

        public bool IsMuted
        {
            get => _isMuted;
            set => SetProperty(ref _isMuted, value);
        }

        public string? StatusMessage
        {
            get => _statusMessage;
            set => SetProperty(ref _statusMessage, value);
        }

        public bool IsLoading
        {
            get => _isLoading;
            set => SetProperty(ref _isLoading, value);
        }

        #endregion

        #region Audio Controls

        public async Task SetVolumeAsync(int newVolume)
        {
            StatusMessage = $"Setting volume to {newVolume}%...";
            SendMQTTCommand($"[volume:{newVolume}]");
            StatusMessage = $"Volume set to {newVolume}%";
            await ClearStatusMessageAsync();
        }

        public async Task ToggleMuteAsync(bool muted)
        {
            StatusMessage = muted ? "Muting audio..." : "Unmuting audio...";
            SendMQTTCommand($"[mute:{muted.ToString().ToLower()}]");
            StatusMessage = muted ? "Audio muted" : "Audio unmuted";
            await ClearStatusMessageAsync();
        }

        #endregion

        #region Camera Controls

        public async Task ToggleCameraAsync(bool enabled)
        {
            StatusMessage = enabled ? "📷 Turning camera ON..." : "📷 Turning camera OFF...";
            SendMQTTCommand($"[camera:{enabled.ToString().ToLower()}]");
            StatusMessage = enabled ? "✅ Camera is ON" : "✅ Camera is OFF";
            await ClearStatusMessageAsync();
        }

        #endregion

        #region Movement Controls

        public async Task MoveAsync(MoveDirection direction)
        {
            StatusMessage = $"Moving {direction}...";
            SendMQTTCommand($"[move:{direction.ToString().ToLower()}]");
            StatusMessage = null;
            await Task.CompletedTask;
        }

        public async Task LookAtAsync(LookDirection direction)
        {
            StatusMessage = $"Looking {direction}...";
            SendMQTTCommand($"[look:{direction.ToString().ToLower()}]");
            StatusMessage = null;
            await Task.CompletedTask;
        }

        public async Task SetArmAsync(ArmSide side, ArmPosition position)
        {
            StatusMessage = $"Setting {side} arm {position}...";
            SendMQTTCommand($"[arm:{side.ToString().ToLower()}:{position.ToString().ToLower()}]");
            StatusMessage = null;
            await Task.CompletedTask;
        }

        #endregion

        #region Face Emotions

        public async Task SetFaceAsync(MoxieEmotion emotion)
        {
            IsLoading = true;
            StatusMessage = $"Setting face to {emotion.Emoji} {emotion.DisplayName}...";

            SendMQTTCommand($"[emotion:{emotion.RawValue}]");
            StatusMessage = $"✅ Face changed to {emotion.Emoji} {emotion.DisplayName}!";

            await ClearStatusMessageAsync();
            IsLoading = false;
        }

        #endregion

        #region Private Methods

        private void SendMQTTCommand(string message)
        {
            _mqttService.SendCommand("control", message);
        }

        private async Task ClearStatusMessageAsync()
        {
            await Task.Delay(2000);
            StatusMessage = null;
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

    #region Supporting Enums

    public enum MoveDirection
    {
        Forward,
        Backward,
        Left,
        Right
    }

    public enum LookDirection
    {
        Up,
        Down,
        Left,
        Right,
        Center
    }

    public enum ArmSide
    {
        Left,
        Right
    }

    public enum ArmPosition
    {
        Up,
        Down,
        Wave,
        Rest
    }

    #endregion
}
