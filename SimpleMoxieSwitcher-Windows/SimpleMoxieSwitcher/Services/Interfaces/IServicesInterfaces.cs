using SimpleMoxieSwitcher.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SimpleMoxieSwitcher.Services.Interfaces;

// MQTT Service
public interface IMQTTService
{
    bool IsConnected { get; }
    Task ConnectAsync();
    Task DisconnectAsync();
    Task SendCommandAsync(string command, string speech);
    Task PublishAsync(string topic, string message);
    event EventHandler<MqttMessageEventArgs>? MessageReceived;
    event EventHandler<bool>? ConnectionStatusChanged;
}

// Docker Service
public interface IDockerService
{
    Task<bool> IsDockerRunningAsync();
    Task<bool> IsContainerRunningAsync();
    Task StartContainerAsync();
    Task StopContainerAsync();
    Task RestartServerAsync();
    Task<string> ExecutePythonScriptAsync(string script);
}

// AI Service
public interface IAIService
{
    Task<string> GenerateResponseAsync(string prompt, AISettings settings);
    Task<bool> ValidateApiKeyAsync(string provider, string apiKey);
    Task<List<string>> GetAvailableModelsAsync(string provider);
    void SetActiveProvider(string provider);
    void SetApiKey(string provider, string apiKey);
}

// Personality Service
public interface IPersonalityService
{
    List<Personality> GetAllPersonalities();
    List<Personality> GetCustomPersonalities();
    Task SwitchPersonalityAsync(Personality personality);
    Task<Personality> CreateCustomPersonalityAsync(string name, string prompt, string emoji);
    Task DeletePersonalityAsync(string personalityId);
    Task UpdatePersonalityAsync(Personality personality);
}

// Settings Service
public interface ISettingsService
{
    bool HasCompletedSetup { get; }
    string GetSetting(string key, string defaultValue = "");
    void SetSetting(string key, string value);
    T GetSetting<T>(string key, T defaultValue = default!);
    void SetSetting<T>(string key, T value);
    void SaveSettings();
}

// Child Profile Service
public interface IChildProfileService
{
    Task<List<ChildProfile>> GetAllProfilesAsync();
    Task<ChildProfile?> GetActiveProfileAsync();
    Task<ChildProfile> CreateProfileAsync(string name, int age, string interests);
    Task UpdateProfileAsync(ChildProfile profile);
    Task DeleteProfileAsync(string profileId);
    Task SetActiveProfileAsync(string profileId);
}

// Content Filter Service
public interface IContentFilterService
{
    Task<bool> IsContentSafeAsync(string content);
    Task<string> FilterContentAsync(string content);
    Task<List<string>> GetFlaggedWordsAsync(string content);
    void SetFilterLevel(ContentFilterLevel level);
    ContentFilterLevel GetCurrentFilterLevel();
}

// Safety Log Service
public interface ISafetyLogService
{
    Task LogInteractionAsync(string userId, string content, bool wasFlagged);
    Task<List<SafetyLogEntry>> GetRecentLogsAsync(int count = 100);
    Task<List<SafetyLogEntry>> GetFlaggedLogsAsync();
    Task ClearLogsAsync();
    Task ExportLogsAsync(string filePath);
}

// Parent Notification Service
public interface IParentNotificationService
{
    Task SendNotificationAsync(string title, string message, NotificationPriority priority);
    Task SendEmailNotificationAsync(string subject, string body);
    Task<List<ParentNotification>> GetPendingNotificationsAsync();
    Task MarkNotificationAsReadAsync(string notificationId);
    void SetNotificationPreferences(NotificationPreferences preferences);
}

// PIN Service
public interface IPINService
{
    bool HasPIN();
    bool VerifyPIN(string pin);
    Task CreatePINAsync(string pin);
    Task ChangePINAsync(string oldPin, string newPin);
    Task ResetPINAsync(string securityAnswer);
    void SetSecurityQuestion(string question, string answer);
}

// Localization Service
public interface ILocalizationService
{
    Language CurrentLanguage { get; }
    string Localize(string key);
    string Localize(string key, params object[] args);
    void SetLanguage(Language language);
    List<Language> GetAvailableLanguages();
}

// Dependency Installation Service
public interface IDependencyInstallationService
{
    bool IsInstalling { get; }
    string InstallationProgress { get; }
    string? InstallationError { get; }
    Task<bool> CheckDockerInstalledAsync();
    Task<bool> CheckMosquittoInstalledAsync();
    Task InstallDockerAsync();
    Task InstallMosquittoAsync();
    Task SetupOpenMoxieContainerAsync();
    Task RunCompleteSetupAsync();
    event EventHandler<string>? ProgressChanged;
    event EventHandler<string>? ErrorOccurred;
    event EventHandler? InstallationCompleted;
}

// Conversation Listener Service
public interface IConversationListenerService
{
    Task StartListeningAsync();
    Task StopListeningAsync();
    event EventHandler<ConversationEventArgs>? ConversationReceived;
}

// Memory Extraction Service
public interface IMemoryExtractionService
{
    Task<List<Memory>> ExtractMemoriesAsync(string conversationText);
    Task<List<Memory>> GetAllMemoriesAsync();
    Task SaveMemoryAsync(Memory memory);
    Task<string> ExportMemoriesToFileAsync(string filePath);
}

// Game Content Generation Service
public interface IGameContentGenerationService
{
    Task<TriviaQuestion> GenerateTriviaQuestionAsync(string topic, string difficulty);
    Task<SpellingChallenge> GenerateSpellingChallengeAsync(int gradeLevel);
    Task<MathProblem> GenerateMathProblemAsync(string type, int difficulty);
    Task<StoryPrompt> GenerateStoryPromptAsync(string genre);
}

// Vocabulary Generation Service
public interface IVocabularyGenerationService
{
    Task<List<VocabularyWord>> GenerateVocabularyListAsync(string language, string topic, int count);
    Task<VocabularyWord> GetWordOfTheDayAsync(string language);
    Task<string> TranslateWordAsync(string word, string fromLanguage, string toLanguage);
    Task<List<string>> GenerateSentencesAsync(string word, string language, int count);
}

// Repository Interfaces
public interface IPersonalityRepository
{
    List<Personality> LoadPersonalities();
    void SavePersonality(Personality personality);
    void DeletePersonality(string personalityId);
}

public interface ITileRepository
{
    List<LearningTile> LoadLearningTiles();
    List<StoryTile> LoadStoryTiles();
    void SaveLearningTile(LearningTile tile);
    void SaveStoryTile(StoryTile tile);
}

public interface IConversationRepository
{
    Task<List<ConversationLog>> GetConversationsAsync(int limit = 50);
    Task SaveConversationAsync(ConversationLog conversation);
    Task<ConversationLog?> GetConversationByIdAsync(string id);
    Task DeleteConversationAsync(string id);
}