using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows.Threading;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;

namespace SimpleMoxieSwitcher.ViewModels
{
    /// <summary>
    /// ViewModel for chat interface with AI conversation management
    /// </summary>
    public class ChatViewModel : INotifyPropertyChanged
    {
        private ObservableCollection<ChatMessage> _messages = new();
        private ObservableCollection<ConversationFile> _conversationHistory = new();
        private ConversationFile? _currentConversationFile;
        private bool _isLoading;
        private string? _errorMessage;
        private Guid _currentConversationId = Guid.NewGuid();

        private readonly Personality _personality;
        private readonly string _conversationsDir;
        private readonly DispatcherTimer _pollingTimer;
        private readonly IAIService _aiService;
        private readonly IChildProfileService _childProfileService;
        private readonly IMemoryStorageService _memoryStorageService;
        private readonly IConversationService _conversationService;
        private readonly ContentFilterService _contentFilterService;
        private readonly ParentNotificationService _parentNotificationService;
        private const int MemoryWindowSize = 20; // Last 20 messages for context

        public ChatViewModel(
            Personality personality,
            IAIService aiService,
            IChildProfileService childProfileService,
            IMemoryStorageService memoryStorageService,
            IConversationService conversationService,
            ContentFilterService contentFilterService,
            ParentNotificationService parentNotificationService)
        {
            _personality = personality;
            _aiService = aiService;
            _childProfileService = childProfileService;
            _memoryStorageService = memoryStorageService;
            _conversationService = conversationService;
            _contentFilterService = contentFilterService;
            _parentNotificationService = parentNotificationService;

            _conversationsDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                ".openmoxie",
                "conversations"
            );

            // Create directory if it doesn't exist
            Directory.CreateDirectory(_conversationsDir);

            // Setup polling timer for voice conversations
            _pollingTimer = new DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(2)
            };
            _pollingTimer.Tick += async (s, e) => await ReloadCurrentConversationAsync();

            // Load child profile
            _ = _childProfileService.LoadProfileAsync();
        }

        #region Properties

        public Personality Personality => _personality;

        public ObservableCollection<ChatMessage> Messages
        {
            get => _messages;
            set => SetProperty(ref _messages, value);
        }

        public ObservableCollection<ConversationFile> ConversationHistory
        {
            get => _conversationHistory;
            set => SetProperty(ref _conversationHistory, value);
        }

        public ConversationFile? CurrentConversationFile
        {
            get => _currentConversationFile;
            set => SetProperty(ref _currentConversationFile, value);
        }

        public bool IsLoading
        {
            get => _isLoading;
            set => SetProperty(ref _isLoading, value);
        }

        public string? ErrorMessage
        {
            get => _errorMessage;
            set => SetProperty(ref _errorMessage, value);
        }

        public Guid CurrentConversationId
        {
            get => _currentConversationId;
            set => SetProperty(ref _currentConversationId, value);
        }

        #endregion

        #region Methods - Conversation Loading

        public async Task LoadConversationHistoryAsync()
        {
            if (!Directory.Exists(_conversationsDir))
            {
                Directory.CreateDirectory(_conversationsDir);
                ConversationHistory.Clear();
                return;
            }

            var files = Directory.GetFiles(_conversationsDir, "*.jsonl", SearchOption.TopDirectoryOnly);
            var loadedConversations = new List<ConversationFile>();

            foreach (var file in files)
            {
                var conversation = LoadConversationFile(file);
                if (conversation != null)
                {
                    loadedConversations.Add(conversation);
                }
            }

            // Sort by last modified (newest first)
            loadedConversations = loadedConversations.OrderByDescending(c => c.LastModified).ToList();
            ConversationHistory = new ObservableCollection<ConversationFile>(loadedConversations);
        }

        private ConversationFile? LoadConversationFile(string path)
        {
            try
            {
                if (!File.Exists(path))
                    return null;

                var fileInfo = new FileInfo(path);
                var lines = File.ReadAllLines(path).Where(l => !string.IsNullOrWhiteSpace(l)).ToList();

                // Get preview from first user message
                var preview = "Empty conversation";
                if (lines.Count > 0)
                {
                    try
                    {
                        var firstMessage = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(lines[0]);
                        if (firstMessage != null && firstMessage.ContainsKey("user"))
                        {
                            var userMessage = firstMessage["user"].GetString() ?? "";
                            preview = userMessage.Length > 60
                                ? userMessage.Substring(0, 60) + "..."
                                : userMessage;
                        }
                    }
                    catch { /* Ignore parsing errors */ }
                }

                return new ConversationFile
                {
                    Id = Path.GetFileName(path),
                    Filename = Path.GetFileName(path),
                    Path = path,
                    MessageCount = lines.Count,
                    LastModified = fileInfo.LastWriteTime,
                    Preview = preview
                };
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading conversation file {path}: {ex.Message}");
                return null;
            }
        }

        public async Task LoadCurrentConversationAsync()
        {
            var filename = $"moxie_{_personality.Name.ToLower().Replace(" ", "_")}_current.jsonl";
            var filePath = Path.Combine(_conversationsDir, filename);

            // Create file if it doesn't exist
            if (!File.Exists(filePath))
            {
                await File.WriteAllTextAsync(filePath, "");
            }

            // Load the conversation
            var conversationFile = LoadConversationFile(filePath);
            if (conversationFile != null)
            {
                await LoadConversationAsync(conversationFile);
            }

            // Start polling for updates (for voice conversations)
            _pollingTimer.Start();
        }

        public async Task LoadConversationAsync(ConversationFile conversation)
        {
            CurrentConversationFile = conversation;

            if (string.IsNullOrEmpty(conversation.Path) || !File.Exists(conversation.Path))
            {
                Messages.Clear();
                return;
            }

            var lines = File.ReadAllLines(conversation.Path).Where(l => !string.IsNullOrWhiteSpace(l));
            var loadedMessages = new List<ChatMessage>();

            foreach (var line in lines)
            {
                try
                {
                    var json = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(line);
                    if (json == null)
                        continue;

                    var user = json.ContainsKey("user") ? json["user"].GetString() : null;
                    var alex = json.ContainsKey("alex") ? json["alex"].GetString() : null;
                    var timestampStr = json.ContainsKey("timestamp") ? json["timestamp"].GetString() : null;

                    if (string.IsNullOrEmpty(user) || string.IsNullOrEmpty(alex))
                        continue;

                    // Parse timestamp
                    var timestamp = DateTime.TryParse(timestampStr, out var ts) ? ts : DateTime.Now;

                    // Add user message
                    loadedMessages.Add(new ChatMessage
                    {
                        Role = "user",
                        Content = user,
                        Timestamp = timestamp
                    });

                    // Add assistant message
                    loadedMessages.Add(new ChatMessage
                    {
                        Role = "assistant",
                        Content = alex,
                        Timestamp = timestamp.AddSeconds(1)
                    });
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error parsing conversation line: {ex.Message}");
                }
            }

            Messages = new ObservableCollection<ChatMessage>(loadedMessages);
            await Task.CompletedTask;
        }

        public async Task StartNewConversationAsync()
        {
            var timestamp = DateTime.Now;
            var filename = $"moxie_{_personality.Name.ToLower().Replace(" ", "_")}_{timestamp:yyyy-MM-dd_HHmmss}.jsonl";
            var filePath = Path.Combine(_conversationsDir, filename);

            // Create empty file
            await File.WriteAllTextAsync(filePath, "");

            // Generate new conversation ID
            CurrentConversationId = Guid.NewGuid();

            // Load it
            var conversationFile = LoadConversationFile(filePath);
            if (conversationFile != null)
            {
                await LoadConversationAsync(conversationFile);
            }

            await LoadConversationHistoryAsync();
        }

        private async Task ReloadCurrentConversationAsync()
        {
            if (CurrentConversationFile != null)
            {
                await LoadConversationAsync(CurrentConversationFile);
            }
        }

        #endregion

        #region Methods - Message Sending

        public async Task SendMessageAsync(string text, string featureType = "conversation")
        {
            if (CurrentConversationFile == null)
                return;

            var currentMode = ModeContext.CurrentMode;

            // Filter content in child mode
            if (currentMode == OperationalMode.Child)
            {
                var category = _contentFilterService.EvaluateChildModeRequest(text);

                switch (category)
                {
                    case ContentCategory.Blocked:
                        await HandleBlockedContentAsync(text);
                        return;

                    case ContentCategory.RequiresParent:
                        await HandleParentRequiredContentAsync(text);
                        return;

                    case ContentCategory.Safe:
                        // Check for concerning content
                        var concernCheck = _contentFilterService.DetectConcerningContent(text);
                        if (concernCheck.IsConcerning && concernCheck.Category != null)
                        {
                            await CreateConcernFlagAsync(text, concernCheck.Category.Value);
                        }
                        break;
                }
            }

            // Add user message to UI
            var userMessage = new ChatMessage
            {
                Role = "user",
                Content = text,
                Timestamp = DateTime.Now
            };
            Messages.Add(userMessage);

            IsLoading = true;
            ErrorMessage = null;

            try
            {
                // Get conversation history window
                var recentMessages = GetConversationMemoryWindow();

                // Generate memory context
                var memoryContext = await GenerateMemoryContextAsync(text);

                // Enhance message with memory context
                var enhancedMessage = text;
                if (!string.IsNullOrEmpty(memoryContext))
                {
                    enhancedMessage = $"{memoryContext}\n\n---\n\nUser: {text}";
                    Console.WriteLine($"🧠 Memory context added ({memoryContext.Length} chars)");
                }

                // Send to AI provider
                var response = await _aiService.SendMessageAsync(
                    enhancedMessage,
                    _personality,
                    featureType,
                    recentMessages
                );

                // Sanitize response
                var sanitizedContent = _contentFilterService.SanitizeResponse(response.Content, currentMode);

                // Add assistant response
                var assistantMessage = new ChatMessage
                {
                    Role = "assistant",
                    Content = sanitizedContent,
                    Timestamp = DateTime.Now
                };
                Messages.Add(assistantMessage);

                // Save to file
                await SaveMessageToFileAsync(text, sanitizedContent, CurrentConversationFile.Path!);

                // Extract interests
                _ = _childProfileService.ExtractAndAddInterestsAsync($"{text} {sanitizedContent}");

                Console.WriteLine($"API Response - Model: {response.Model}, Tokens: {response.TotalTokens}, Time: {response.ResponseTime}s");
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Failed to send message: {ex.Message}";
                Messages.Remove(userMessage);
            }

            IsLoading = false;
        }

        private async Task HandleBlockedContentAsync(string message)
        {
            // Add user message
            Messages.Add(new ChatMessage
            {
                Role = "user",
                Content = message,
                Timestamp = DateTime.Now
            });

            // Add blocked response
            var blockedResponse = _contentFilterService.GetChildModeBlockedResponse(message);
            Messages.Add(new ChatMessage
            {
                Role = "assistant",
                Content = blockedResponse,
                Timestamp = DateTime.Now
            });

            // Save to file
            if (CurrentConversationFile != null && !string.IsNullOrEmpty(CurrentConversationFile.Path))
            {
                await SaveMessageToFileAsync(message, blockedResponse, CurrentConversationFile.Path);
            }

            // Log blocked content
            Console.WriteLine($"⚠️ Content blocked in child mode");
        }

        private async Task HandleParentRequiredContentAsync(string message)
        {
            // Add user message
            Messages.Add(new ChatMessage
            {
                Role = "user",
                Content = message,
                Timestamp = DateTime.Now
            });

            // Add redirect response
            var redirectResponse = _contentFilterService.GetChildModeParentRequiredResponse(message);
            Messages.Add(new ChatMessage
            {
                Role = "assistant",
                Content = redirectResponse,
                Timestamp = DateTime.Now
            });

            // Save to file
            if (CurrentConversationFile != null && !string.IsNullOrEmpty(CurrentConversationFile.Path))
            {
                await SaveMessageToFileAsync(message, redirectResponse, CurrentConversationFile.Path);
            }

            // Create parent notification
            await _parentNotificationService.NotifyParentAsync(
                "Parent Required Content",
                $"Child asked: {message.Substring(0, Math.Min(100, message.Length))}...",
                NotificationSeverity.Low
            );
        }

        private async Task CreateConcernFlagAsync(string message, ConcernCategory category)
        {
            var severity = category switch
            {
                ConcernCategory.SafetyRisk => NotificationSeverity.High,
                ConcernCategory.EmotionalDistress => NotificationSeverity.Medium,
                ConcernCategory.BullyingIndicator => NotificationSeverity.Medium,
                ConcernCategory.SocialIsolation => NotificationSeverity.Low,
                _ => NotificationSeverity.Low
            };

            await _parentNotificationService.NotifyParentAsync(
                $"Concern Detected: {category}",
                $"Child said: {message.Substring(0, Math.Min(100, message.Length))}...",
                severity
            );

            Console.WriteLine($"🚨 Concern flagged: {category} - Severity: {severity}");
        }

        private async Task SaveMessageToFileAsync(string user, string assistant, string filePath)
        {
            var entry = new Dictionary<string, object>
            {
                ["timestamp"] = DateTime.Now.ToString("o"),
                ["user"] = user,
                ["alex"] = assistant,
                ["personality"] = _personality.Name,
                ["personality_emoji"] = _personality.Emoji
            };

            try
            {
                var jsonString = JsonSerializer.Serialize(entry);
                await File.AppendAllTextAsync(filePath, jsonString + "\n");

                // Reload conversation history
                await LoadConversationHistoryAsync();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to save message: {ex.Message}");
            }
        }

        #endregion

        #region Methods - Memory & Context

        private List<ChatMessage> GetConversationMemoryWindow()
        {
            // Don't include the last message (the one we just added)
            var messagesToConsider = Messages.Take(Messages.Count - 1).ToList();

            // Return last N messages
            if (messagesToConsider.Count > MemoryWindowSize)
            {
                return messagesToConsider.Skip(messagesToConsider.Count - MemoryWindowSize).ToList();
            }

            return messagesToConsider;
        }

        private async Task<string> GenerateMemoryContextAsync(string message)
        {
            try
            {
                var keywords = ExtractKeywords(message);

                // Load frontal cortex
                var cortex = await _memoryStorageService.LoadFrontalCortexAsync();
                var cortexContext = cortex?.GenerateContextForAI() ?? "";

                // Load relevant memories
                var memoryContext = await _memoryStorageService.GenerateContextForAIAsync(keywords, 5);

                // Combine contexts
                if (!string.IsNullOrEmpty(cortexContext) && !string.IsNullOrEmpty(memoryContext))
                {
                    return $"{cortexContext}\n\n{memoryContext}";
                }

                return cortexContext + memoryContext;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to generate memory context: {ex.Message}");
                return "";
            }
        }

        private List<string> ExtractKeywords(string text)
        {
            var stopWords = new HashSet<string>
            {
                "the", "a", "an", "is", "are", "was", "were", "to", "of", "and", "or", "but",
                "in", "on", "at", "by", "for", "with", "about", "as", "from", "i", "you", "me",
                "my", "your"
            };

            var words = text.ToLower()
                .Split(new[] { ' ', '\t', '\n', '\r', '.', ',', '!', '?' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(w => w.Trim())
                .Where(w => !stopWords.Contains(w) && w.Length > 2)
                .Take(5)
                .ToList();

            return words;
        }

        #endregion

        #region Methods - Polling

        public void StartPolling()
        {
            _pollingTimer.Start();
        }

        public void StopPolling()
        {
            _pollingTimer.Stop();
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
