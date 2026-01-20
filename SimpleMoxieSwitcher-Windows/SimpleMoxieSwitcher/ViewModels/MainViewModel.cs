using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.UI.Xaml.Media;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services.Interfaces;
using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using Windows.UI;

namespace SimpleMoxieSwitcher.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly IPersonalityService _personalityService;
    private readonly IDockerService _dockerService;
    private readonly ISettingsService _settingsService;
    private readonly ITileRepository _tileRepository;
    private readonly ILocalizationService _localizationService;
    private System.Timers.Timer? _statusCheckTimer;

    [ObservableProperty]
    private bool _isUpdating;

    [ObservableProperty]
    private string? _statusMessage;

    [ObservableProperty]
    private bool _hasStatusMessage;

    [ObservableProperty]
    private Brush? _statusMessageColor;

    [ObservableProperty]
    private bool _isOnline;

    [ObservableProperty]
    private DateTime? _onlineTime;

    [ObservableProperty]
    private string _statusText = "Offline";

    [ObservableProperty]
    private Language _selectedLanguage;

    public ObservableCollection<ITileItem> AllItems { get; } = new();
    public ObservableCollection<Language> Languages { get; } = new();

    public MainViewModel(
        IPersonalityService personalityService,
        IDockerService dockerService,
        ISettingsService settingsService,
        ITileRepository tileRepository,
        ILocalizationService localizationService)
    {
        _personalityService = personalityService;
        _dockerService = dockerService;
        _settingsService = settingsService;
        _tileRepository = tileRepository;
        _localizationService = localizationService;

        InitializeLanguages();
        LoadTiles();
        StartStatusMonitoring();
    }

    private void InitializeLanguages()
    {
        foreach (var language in Language.AllLanguages)
        {
            Languages.Add(language);
        }

        var currentLanguage = _localizationService.CurrentLanguage;
        SelectedLanguage = Languages.FirstOrDefault(l => l.Code == currentLanguage.Code) ?? Languages[0];
    }

    partial void OnSelectedLanguageChanged(Language value)
    {
        _localizationService.SetLanguage(value);
        _ = UpdateOpenMoxieLanguageAsync(value);
    }

    private void LoadTiles()
    {
        AllItems.Clear();

        // Add feature tiles
        AllItems.Add(new FeatureTile
        {
            Id = "child_profile",
            DisplayName = "Child Profile",
            Emoji = "👶",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Purple, Colors.Indigo)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "custom_creator",
            DisplayName = "Custom Creator",
            Emoji = "✨",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Gold, Colors.Orange)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "appearance",
            DisplayName = "Appearance",
            Emoji = "🎨",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Pink, Colors.Purple)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "chat",
            DisplayName = "Chat",
            Emoji = "💬",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Blue, Colors.Cyan)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "story_time",
            DisplayName = "Story Time",
            Emoji = "📚",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Teal, Colors.Green)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "learning",
            DisplayName = "Learning",
            Emoji = "🧠",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Blue, Colors.Purple)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "language",
            DisplayName = "Language",
            Emoji = "🌍",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Green, Colors.Blue)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "music",
            DisplayName = "Music",
            Emoji = "🎵",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Red, Colors.Pink)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "smart_home",
            DisplayName = "Smart Home",
            Emoji = "🏠",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Orange, Colors.Yellow)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "puppet_mode",
            DisplayName = "Puppet Mode",
            Emoji = "🎭",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Purple, Colors.Pink)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "games",
            DisplayName = "Games",
            Emoji = "🎮",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Green, Colors.Yellow)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "settings",
            DisplayName = "Settings",
            Emoji = "⚙️",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Gray, Colors.DarkGray)
        });

        AllItems.Add(new FeatureTile
        {
            Id = "documentation",
            DisplayName = "Documentation",
            Emoji = "📖",
            EmojiSize = 50,
            BackgroundBrush = CreateGradientBrush(Colors.Blue, Colors.DarkBlue)
        });

        // Add start Docker tile if offline
        if (!IsOnline)
        {
            AllItems.Insert(0, new FeatureTile
            {
                Id = "start_docker",
                DisplayName = "Start Docker",
                Emoji = "🐳",
                EmojiSize = 50,
                BackgroundBrush = CreateGradientBrush(Colors.Blue, Colors.DarkBlue)
            });
        }

        // Load personalities
        var personalities = _personalityService.GetAllPersonalities();
        foreach (var personality in personalities)
        {
            AllItems.Add(personality);
        }

        // Load learning tiles
        var learningTiles = _tileRepository.LoadLearningTiles();
        foreach (var tile in learningTiles)
        {
            AllItems.Add(tile);
        }

        // Load story tiles
        var storyTiles = _tileRepository.LoadStoryTiles();
        foreach (var tile in storyTiles)
        {
            AllItems.Add(tile);
        }
    }

    private LinearGradientBrush CreateGradientBrush(Color start, Color end)
    {
        var brush = new LinearGradientBrush();
        brush.StartPoint = new Windows.Foundation.Point(0, 0);
        brush.EndPoint = new Windows.Foundation.Point(1, 1);
        brush.GradientStops.Add(new GradientStop { Color = start, Offset = 0 });
        brush.GradientStops.Add(new GradientStop { Color = end, Offset = 1 });
        return brush;
    }

    private void StartStatusMonitoring()
    {
        _ = CheckMoxieStatusAsync();

        _statusCheckTimer = new System.Timers.Timer(5000);
        _statusCheckTimer.Elapsed += async (s, e) => await CheckMoxieStatusAsync();
        _statusCheckTimer.Start();
    }

    private async Task CheckMoxieStatusAsync()
    {
        var endpoint = _settingsService.GetSetting("moxieEndpoint", "http://localhost:8003/hive/endpoint/");

        try
        {
            using var client = new System.Net.Http.HttpClient();
            client.Timeout = TimeSpan.FromSeconds(2);
            var response = await client.GetAsync(endpoint);

            if (response.IsSuccessStatusCode)
            {
                if (!IsOnline)
                {
                    OnlineTime = DateTime.Now;
                }
                IsOnline = true;
                UpdateStatusText();
            }
            else
            {
                IsOnline = false;
                OnlineTime = null;
                StatusText = "Offline";
            }
        }
        catch
        {
            IsOnline = false;
            OnlineTime = null;
            StatusText = "Offline";
        }
    }

    private void UpdateStatusText()
    {
        if (IsOnline && OnlineTime.HasValue)
        {
            var uptime = DateTime.Now - OnlineTime.Value;
            if (uptime.TotalHours >= 1)
            {
                StatusText = $"Online - {(int)uptime.TotalHours}h {uptime.Minutes}m {uptime.Seconds}s";
            }
            else if (uptime.TotalMinutes >= 1)
            {
                StatusText = $"Online - {uptime.Minutes}m {uptime.Seconds}s";
            }
            else
            {
                StatusText = $"Online - {uptime.Seconds}s";
            }
        }
        else if (IsOnline)
        {
            StatusText = "Online";
        }
        else
        {
            StatusText = "Offline";
        }
    }

    public async Task HandleTileClickAsync(ITileItem tileItem)
    {
        switch (tileItem)
        {
            case FeatureTile feature:
                await HandleFeatureTileAsync(feature.Id);
                break;
            case Personality personality:
                await SwitchPersonalityAsync(personality);
                break;
            case LearningTile learning:
                await OpenLearningSessionAsync(learning);
                break;
            case StoryTile story:
                await OpenStorySessionAsync(story);
                break;
        }
    }

    private async Task HandleFeatureTileAsync(string featureId)
    {
        switch (featureId)
        {
            case "start_docker":
                await StartDockerContainerAsync();
                break;
            case "child_profile":
                await OpenChildProfileAsync();
                break;
            case "custom_creator":
                await OpenCustomCreatorAsync();
                break;
            case "appearance":
                await OpenAppearanceAsync();
                break;
            case "chat":
                await OpenChatAsync();
                break;
            case "story_time":
                await OpenStoryTimeAsync();
                break;
            case "learning":
                await OpenLearningAsync();
                break;
            case "language":
                await OpenLanguageAsync();
                break;
            case "music":
                await OpenMusicAsync();
                break;
            case "smart_home":
                await OpenSmartHomeAsync();
                break;
            case "puppet_mode":
                await OpenPuppetModeAsync();
                break;
            case "games":
                await OpenGamesAsync();
                break;
            case "settings":
                await OpenSettingsAsync();
                break;
            case "documentation":
                await OpenDocumentationAsync();
                break;
        }
    }

    [RelayCommand]
    private async Task StartDockerContainerAsync()
    {
        IsUpdating = true;
        StatusMessage = "Starting Docker container...";
        HasStatusMessage = true;
        StatusMessageColor = new SolidColorBrush(Colors.White);

        try
        {
            await _dockerService.StartContainerAsync();
            StatusMessage = "✅ Docker container started successfully!";
            StatusMessageColor = new SolidColorBrush(Colors.LimeGreen);
            await CheckMoxieStatusAsync();
        }
        catch (Exception ex)
        {
            StatusMessage = $"❌ Failed to start Docker: {ex.Message}";
            StatusMessageColor = new SolidColorBrush(Colors.Red);
        }

        await Task.Delay(3000);
        HasStatusMessage = false;
        StatusMessage = null;
        IsUpdating = false;
    }

    private async Task SwitchPersonalityAsync(Personality personality)
    {
        IsUpdating = true;
        StatusMessage = $"Switching to {personality.Name}...";
        HasStatusMessage = true;
        StatusMessageColor = new SolidColorBrush(Colors.White);

        try
        {
            await _personalityService.SwitchPersonalityAsync(personality);
            StatusMessage = $"✅ SUCCESS! Moxie is now {personality.Emoji} {personality.Name}!";
            StatusMessageColor = new SolidColorBrush(Colors.LimeGreen);
        }
        catch (Exception ex)
        {
            StatusMessage = $"❌ Error: {ex.Message}";
            StatusMessageColor = new SolidColorBrush(Colors.Red);
        }

        await Task.Delay(3000);
        HasStatusMessage = false;
        StatusMessage = null;
        IsUpdating = false;
    }

    private async Task UpdateOpenMoxieLanguageAsync(Language language)
    {
        try
        {
            var script = $@"
import os
os.environ['MOXIE_LANGUAGE'] = '{language.Name}'
os.environ['MOXIE_LANGUAGE_CODE'] = '{language.Code}'

from hive.models import MoxieDevice, PersistentData
device = MoxieDevice.objects.filter(device_id='moxie_001').first()
if device:
    persist, created = PersistentData.objects.get_or_create(device=device, defaults={{'data': {{}}}})
    data = persist.data or {{}}
    data['language_preference'] = {{
        'code': '{language.Code}',
        'name': '{language.Name}'
    }}
    persist.data = data
    persist.save()
    print(f'Language updated to: {language.Name}')
";
            await _dockerService.ExecutePythonScriptAsync(script);
            await _dockerService.RestartServerAsync();
        }
        catch (Exception ex)
        {
            // Log error
        }
    }

    // Dialog opening methods
    private async Task OpenChildProfileAsync()
    {
        var dialog = new ChildProfileDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenCustomCreatorAsync()
    {
        var dialog = new CustomPersonalityDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenAppearanceAsync()
    {
        var dialog = new AppearanceDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenChatAsync()
    {
        var dialog = new AllConversationsDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenStoryTimeAsync()
    {
        var dialog = new StoryTimeDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenLearningAsync()
    {
        var dialog = new LearningDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenLanguageAsync()
    {
        var dialog = new LanguageDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenMusicAsync()
    {
        var dialog = new MusicDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenSmartHomeAsync()
    {
        var dialog = new SmartHomeDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenPuppetModeAsync()
    {
        var dialog = new PuppetModeDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenGamesAsync()
    {
        var dialog = new GamesMenuDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenSettingsAsync()
    {
        var dialog = new SettingsDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenDocumentationAsync()
    {
        var dialog = new DocumentationDialog();
        await dialog.ShowAsync();
    }

    private async Task OpenLearningSessionAsync(LearningTile tile)
    {
        var dialog = new LearningDialog();
        dialog.LoadSession(tile);
        await dialog.ShowAsync();
    }

    private async Task OpenStorySessionAsync(StoryTile tile)
    {
        var dialog = new StoryTimeDialog();
        dialog.LoadSession(tile);
        await dialog.ShowAsync();
    }
}