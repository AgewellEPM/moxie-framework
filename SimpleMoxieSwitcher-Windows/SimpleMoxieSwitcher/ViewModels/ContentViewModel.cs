using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Net.Http;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Threading;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;

namespace SimpleMoxieSwitcher.ViewModels
{
    /// <summary>
    /// Main ViewModel for the application content and navigation
    /// </summary>
    public class ContentViewModel : INotifyPropertyChanged
    {
        private bool _isUpdating;
        private string? _statusMessage;
        private ObservableCollection<Personality> _allPersonalities = new();
        private bool _showCustomCreator;
        private bool _showAppearance;
        private bool _showConversations;
        private bool _showSettings;
        private Personality? _editingPersonality;
        private bool _showPersonalityEditor;
        private bool _showChat;
        private bool _showStoryTime;
        private bool _showLearning;
        private bool _showLanguage;
        private bool _showMusic;
        private bool _showSmartHome;
        private bool _showPuppetMode;
        private bool _showChildProfile;
        private bool _showGames;
        private bool _showDocumentation;
        private bool _showModelSelector;
        private Personality? _selectedPersonalityForChat;
        private bool _showSetupWizard;
        private bool _isStartingDocker;
        private bool _isOnline;
        private DateTime? _onlineTime;
        private ObservableCollection<LearningTile> _learningTiles = new();
        private ObservableCollection<StoryTile> _storyTiles = new();

        private readonly IPersonalityService _personalityService;
        private readonly DispatcherTimer _statusCheckTimer;
        private readonly HttpClient _httpClient;

        public ContentViewModel(IPersonalityService personalityService)
        {
            _personalityService = personalityService;
            _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };

            LoadPersonalities();
            LoadTiles();
            CheckFirstLaunch();

            // Start status monitoring
            _statusCheckTimer = new DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(5)
            };
            _statusCheckTimer.Tick += async (s, e) => await CheckMoxieStatusAsync();
            _statusCheckTimer.Start();

            // Check immediately
            _ = CheckMoxieStatusAsync();
        }

        #region Properties

        public bool IsUpdating
        {
            get => _isUpdating;
            set => SetProperty(ref _isUpdating, value);
        }

        public string? StatusMessage
        {
            get => _statusMessage;
            set => SetProperty(ref _statusMessage, value);
        }

        public ObservableCollection<Personality> AllPersonalities
        {
            get => _allPersonalities;
            set => SetProperty(ref _allPersonalities, value);
        }

        public bool ShowCustomCreator
        {
            get => _showCustomCreator;
            set => SetProperty(ref _showCustomCreator, value);
        }

        public bool ShowAppearance
        {
            get => _showAppearance;
            set => SetProperty(ref _showAppearance, value);
        }

        public bool ShowConversations
        {
            get => _showConversations;
            set => SetProperty(ref _showConversations, value);
        }

        public bool ShowSettings
        {
            get => _showSettings;
            set => SetProperty(ref _showSettings, value);
        }

        public Personality? EditingPersonality
        {
            get => _editingPersonality;
            set => SetProperty(ref _editingPersonality, value);
        }

        public bool ShowPersonalityEditor
        {
            get => _showPersonalityEditor;
            set => SetProperty(ref _showPersonalityEditor, value);
        }

        public bool ShowChat
        {
            get => _showChat;
            set => SetProperty(ref _showChat, value);
        }

        public bool ShowStoryTime
        {
            get => _showStoryTime;
            set => SetProperty(ref _showStoryTime, value);
        }

        public bool ShowLearning
        {
            get => _showLearning;
            set => SetProperty(ref _showLearning, value);
        }

        public bool ShowLanguage
        {
            get => _showLanguage;
            set => SetProperty(ref _showLanguage, value);
        }

        public bool ShowMusic
        {
            get => _showMusic;
            set => SetProperty(ref _showMusic, value);
        }

        public bool ShowSmartHome
        {
            get => _showSmartHome;
            set => SetProperty(ref _showSmartHome, value);
        }

        public bool ShowPuppetMode
        {
            get => _showPuppetMode;
            set => SetProperty(ref _showPuppetMode, value);
        }

        public bool ShowChildProfile
        {
            get => _showChildProfile;
            set => SetProperty(ref _showChildProfile, value);
        }

        public bool ShowGames
        {
            get => _showGames;
            set => SetProperty(ref _showGames, value);
        }

        public bool ShowDocumentation
        {
            get => _showDocumentation;
            set => SetProperty(ref _showDocumentation, value);
        }

        public bool ShowModelSelector
        {
            get => _showModelSelector;
            set => SetProperty(ref _showModelSelector, value);
        }

        public Personality? SelectedPersonalityForChat
        {
            get => _selectedPersonalityForChat;
            set => SetProperty(ref _selectedPersonalityForChat, value);
        }

        public bool ShowSetupWizard
        {
            get => _showSetupWizard;
            set => SetProperty(ref _showSetupWizard, value);
        }

        public bool IsStartingDocker
        {
            get => _isStartingDocker;
            set => SetProperty(ref _isStartingDocker, value);
        }

        public bool IsOnline
        {
            get => _isOnline;
            set => SetProperty(ref _isOnline, value);
        }

        public DateTime? OnlineTime
        {
            get => _onlineTime;
            set => SetProperty(ref _onlineTime, value);
        }

        public ObservableCollection<LearningTile> LearningTiles
        {
            get => _learningTiles;
            set => SetProperty(ref _learningTiles, value);
        }

        public ObservableCollection<StoryTile> StoryTiles
        {
            get => _storyTiles;
            set => SetProperty(ref _storyTiles, value);
        }

        #endregion

        #region Methods

        public void CheckFirstLaunch()
        {
            var hasCompletedSetup = Properties.Settings.Default.HasCompletedSetup;
            if (!hasCompletedSetup)
            {
                ShowSetupWizard = true;
            }
        }

        public async Task CheckMoxieStatusAsync()
        {
            var endpoint = Properties.Settings.Default.MoxieEndpoint;
            if (string.IsNullOrEmpty(endpoint))
            {
                endpoint = "http://localhost:8003/hive/endpoint/";
            }

            if (!Uri.TryCreate(endpoint, UriKind.Absolute, out var uri))
            {
                IsOnline = false;
                OnlineTime = null;
                return;
            }

            try
            {
                var response = await _httpClient.GetAsync(uri);
                if (response.IsSuccessStatusCode)
                {
                    if (!IsOnline)
                    {
                        // Just came online
                        OnlineTime = DateTime.Now;
                    }
                    IsOnline = true;
                }
                else
                {
                    IsOnline = false;
                    OnlineTime = null;
                }
            }
            catch
            {
                IsOnline = false;
                OnlineTime = null;
            }
        }

        public void LoadPersonalities()
        {
            var builtInPersonalities = Personality.GetAllPersonalities();
            AllPersonalities = new ObservableCollection<Personality>(builtInPersonalities);
        }

        public void LoadTiles()
        {
            // TODO: Load from database or file system
            LearningTiles = new ObservableCollection<LearningTile>();
            StoryTiles = new ObservableCollection<StoryTile>();
        }

        public async Task SwitchPersonalityAsync(Personality personality)
        {
            IsUpdating = true;
            StatusMessage = $"Switching to {personality.Name}...";

            try
            {
                await _personalityService.SwitchPersonalityAsync(personality);
                StatusMessage = $"✅ SUCCESS! Moxie is now {personality.Emoji} {personality.Name}!";

                // Clear status after delay
                await Task.Delay(3000);
                StatusMessage = null;
            }
            catch (Exception ex)
            {
                StatusMessage = $"❌ Error: {ex.Message}";
            }

            IsUpdating = false;
        }

        public void EditPersonality(Personality personality)
        {
            EditingPersonality = personality;
            ShowPersonalityEditor = true;
        }

        public void OpenChat(Personality personality)
        {
            SelectedPersonalityForChat = personality;
            ShowChat = true;
        }

        public async Task StartDockerContainerAsync()
        {
            IsStartingDocker = true;
            StatusMessage = "Starting Docker container...";

            try
            {
                // Use Docker CLI to start container
                var process = new System.Diagnostics.Process
                {
                    StartInfo = new System.Diagnostics.ProcessStartInfo
                    {
                        FileName = "docker",
                        Arguments = "start openmoxie",
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };

                process.Start();
                var output = await process.StandardOutput.ReadToEndAsync();
                var error = await process.StandardError.ReadToEndAsync();
                await process.WaitForExitAsync();

                if (process.ExitCode == 0)
                {
                    StatusMessage = "✅ Docker container started successfully!";
                    await CheckMoxieStatusAsync();
                }
                else
                {
                    // Try running a new container
                    var runProcess = new System.Diagnostics.Process
                    {
                        StartInfo = new System.Diagnostics.ProcessStartInfo
                        {
                            FileName = "docker",
                            Arguments = "run -d --name openmoxie -p 8003:8003 embodied/openmoxie:latest",
                            RedirectStandardOutput = true,
                            RedirectStandardError = true,
                            UseShellExecute = false,
                            CreateNoWindow = true
                        }
                    };

                    runProcess.Start();
                    await runProcess.WaitForExitAsync();

                    if (runProcess.ExitCode == 0)
                    {
                        StatusMessage = "✅ Docker container created and started successfully!";
                        await CheckMoxieStatusAsync();
                    }
                    else
                    {
                        StatusMessage = $"❌ Failed to start Docker: {error}";
                    }
                }
            }
            catch (Exception ex)
            {
                StatusMessage = $"❌ Error starting Docker: {ex.Message}";
            }

            // Clear status after delay
            await Task.Delay(3000);
            StatusMessage = null;
            IsStartingDocker = false;
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
