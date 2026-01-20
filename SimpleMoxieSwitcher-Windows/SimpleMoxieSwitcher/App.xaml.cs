using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.UI.Xaml;
using SimpleMoxieSwitcher.Services;
using SimpleMoxieSwitcher.Services.Interfaces;
using SimpleMoxieSwitcher.ViewModels;
using SimpleMoxieSwitcher.Views;
using System;
using System.Threading.Tasks;

namespace SimpleMoxieSwitcher;

public partial class App : Application
{
    private Window? _window;
    private IHost? _host;

    public IServiceProvider Services => _host!.Services;
    public static App Current => (App)Application.Current;
    public Window MainWindow => _window!;

    public App()
    {
        InitializeComponent();
        _host = CreateHostBuilder().Build();
    }

    protected override async void OnLaunched(LaunchActivatedEventArgs args)
    {
        // Start the host
        await _host!.StartAsync();

        // Create main window
        _window = new MainWindow();
        _window.Activate();

        // Start background services
        var conversationListener = Services.GetRequiredService<IConversationListenerService>();
        _ = Task.Run(async () => await conversationListener.StartListeningAsync());

        // Check if first launch
        var settings = Services.GetRequiredService<ISettingsService>();
        if (!settings.HasCompletedSetup)
        {
            // Show setup wizard
            var setupWindow = new SetupWizardWindow();
            setupWindow.Activate();
        }
    }

    private static IHostBuilder CreateHostBuilder()
    {
        return Host.CreateDefaultBuilder()
            .ConfigureServices((context, services) =>
            {
                // Register services
                services.AddSingleton<ISettingsService, SettingsService>();
                services.AddSingleton<IMQTTService, MQTTService>();
                services.AddSingleton<IDockerService, DockerService>();
                services.AddSingleton<IAIService, AIService>();
                services.AddSingleton<IPersonalityService, PersonalityService>();
                services.AddSingleton<IConversationListenerService, ConversationListenerService>();
                services.AddSingleton<IChildProfileService, ChildProfileService>();
                services.AddSingleton<IContentFilterService, ContentFilterService>();
                services.AddSingleton<ISafetyLogService, SafetyLogService>();
                services.AddSingleton<IParentNotificationService, ParentNotificationService>();
                services.AddSingleton<IPINService, PINService>();
                services.AddSingleton<ILocalizationService, LocalizationService>();
                services.AddSingleton<IDependencyInstallationService, DependencyInstallationService>();
                services.AddSingleton<IMemoryExtractionService, MemoryExtractionService>();
                services.AddSingleton<IGameContentGenerationService, GameContentGenerationService>();
                services.AddSingleton<IVocabularyGenerationService, VocabularyGenerationService>();

                // Register repositories
                services.AddSingleton<IPersonalityRepository, PersonalityRepository>();
                services.AddSingleton<ITileRepository, TileRepository>();
                services.AddSingleton<IConversationRepository, ConversationRepository>();

                // Register ViewModels
                services.AddTransient<MainViewModel>();
                services.AddTransient<SetupWizardViewModel>();
                services.AddTransient<SettingsViewModel>();
                services.AddTransient<ChatInterfaceViewModel>();
                services.AddTransient<PersonalityViewModel>();
                services.AddTransient<ChildProfileViewModel>();
                services.AddTransient<StoryTimeViewModel>();
                services.AddTransient<LearningViewModel>();
                services.AddTransient<LanguageViewModel>();
                services.AddTransient<MusicViewModel>();
                services.AddTransient<GamesViewModel>();
                services.AddTransient<SmartHomeViewModel>();
                services.AddTransient<PuppetModeViewModel>();
                services.AddTransient<DocumentationViewModel>();
                services.AddTransient<ModelSelectorViewModel>();
            });
    }
}