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
    /// ViewModel for customizing Moxie's appearance
    /// </summary>
    public class AppearanceViewModel : INotifyPropertyChanged
    {
        private bool _isApplying;
        private string? _statusMessage;

        private readonly IAppearanceService _appearanceService;
        private readonly IMQTTService _mqttService;

        public AppearanceViewModel(IAppearanceService appearanceService, IMQTTService mqttService)
        {
            _appearanceService = appearanceService;
            _mqttService = mqttService;
        }

        #region Properties

        public bool IsApplying
        {
            get => _isApplying;
            set => SetProperty(ref _isApplying, value);
        }

        public string? StatusMessage
        {
            get => _statusMessage;
            set => SetProperty(ref _statusMessage, value);
        }

        #endregion

        #region Methods

        public async Task ApplyAppearanceAsync(
            string eyes,
            string faceColors,
            string eyeDesigns,
            string faceDesigns,
            string eyelidDesigns,
            string mouth,
            string headHair,
            string facialHair,
            string brows,
            string glasses,
            string nose)
        {
            IsApplying = true;
            StatusMessage = "Applying appearance changes...";

            var appearance = new AppearanceSettings
            {
                Eyes = eyes,
                FaceColors = faceColors,
                EyeDesigns = eyeDesigns,
                FaceDesigns = faceDesigns,
                EyelidDesigns = eyelidDesigns,
                Mouth = mouth,
                HeadHair = headHair,
                FacialHair = facialHair,
                Brows = brows,
                Glasses = glasses,
                Nose = nose
            };

            await _appearanceService.ApplyAppearanceAsync(appearance);

            IsApplying = false;
            StatusMessage = "Appearance updated successfully!";
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

    #region Supporting Models

    /// <summary>
    /// Settings for customizing Moxie's appearance
    /// </summary>
    public class AppearanceSettings
    {
        public string Eyes { get; set; } = "";
        public string FaceColors { get; set; } = "";
        public string EyeDesigns { get; set; } = "";
        public string FaceDesigns { get; set; } = "";
        public string EyelidDesigns { get; set; } = "";
        public string Mouth { get; set; } = "";
        public string HeadHair { get; set; } = "";
        public string FacialHair { get; set; } = "";
        public string Brows { get; set; } = "";
        public string Glasses { get; set; } = "";
        public string Nose { get; set; } = "";
    }

    #endregion
}
