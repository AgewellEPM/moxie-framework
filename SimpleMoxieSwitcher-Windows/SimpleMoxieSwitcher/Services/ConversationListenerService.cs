using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for listening to Moxie conversation MQTT topics and persisting them
    /// </summary>
    public class ConversationListenerService : IConversationListenerService
    {
        private readonly IMQTTService _mqttService;
        private readonly string _conversationsDir;
        private string _currentConversationFile;
        private string _currentPersonality = "Default";
        private string _currentPersonalityEmoji = "🤖";
        private string _pendingUserMessage;
        private DateTime? _pendingUserTimestamp;

        public bool IsListening { get; private set; }
        public DateTime? LastMessageReceived { get; private set; }
        public int MessageCount { get; private set; }

        public event EventHandler<ConversationMessageEventArgs> MessageReceived;

        public ConversationListenerService(IMQTTService mqttService)
        {
            _mqttService = mqttService;

            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            _conversationsDir = Path.Combine(appData, "SimpleMoxieSwitcher", "Conversations");
            Directory.CreateDirectory(_conversationsDir);

            // Subscribe to MQTT messages
            _mqttService.MessageReceived += OnMQTTMessageReceived;
        }

        public async Task StartListeningAsync()
        {
            if (IsListening) return;

            Console.WriteLine("📡 Starting MQTT conversation listener...");

            // Subscribe to conversation topics
            await _mqttService.PublishAsync("moxie/conversation/#", "");

            IsListening = true;
            Console.WriteLine("✅ MQTT listener started successfully");
        }

        public Task StopListeningAsync()
        {
            if (!IsListening) return Task.CompletedTask;

            Console.WriteLine("🛑 Stopping MQTT conversation listener...");
            IsListening = false;
            Console.WriteLine("✅ MQTT listener stopped");

            return Task.CompletedTask;
        }

        private void OnMQTTMessageReceived(object sender, MqttMessageEventArgs e)
        {
            if (!IsListening) return;

            var topic = e.Topic;
            var payload = e.Payload;

            // Parse different conversation message types
            if (topic.Contains("moxie/conversation/user"))
            {
                HandleUserMessage(payload);
            }
            else if (topic.Contains("moxie/conversation/assistant"))
            {
                HandleAssistantMessage(payload);
            }
            else if (topic.Contains("moxie/conversation/start"))
            {
                HandleConversationStart(payload);
            }
            else if (topic.Contains("moxie/conversation/metadata"))
            {
                HandleConversationMetadata(payload);
            }
        }

        private void HandleUserMessage(string payload)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var json = JsonSerializer.Deserialize<Dictionary<string, object>>(payload, options);

                if (json != null && json.ContainsKey("text"))
                {
                    var text = json["text"].ToString();
                    Console.WriteLine($"👤 User: {text}");

                    // Store for pairing with assistant response
                    _pendingUserMessage = text;
                    _pendingUserTimestamp = DateTime.Now;

                    MessageReceived?.Invoke(this, new ConversationMessageEventArgs
                    {
                        IsUser = true,
                        Message = text,
                        Timestamp = DateTime.Now
                    });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error handling user message: {ex.Message}");
            }
        }

        private async void HandleAssistantMessage(string payload)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var json = JsonSerializer.Deserialize<Dictionary<string, object>>(payload, options);

                if (json != null && json.ContainsKey("text"))
                {
                    var text = json["text"].ToString();
                    Console.WriteLine($"🤖 Moxie: {text}");

                    // Get pending user message
                    if (string.IsNullOrEmpty(_pendingUserMessage) || !_pendingUserTimestamp.HasValue)
                    {
                        Console.WriteLine("⚠️ No pending user message to pair with assistant response");
                        return;
                    }

                    // Save conversation exchange
                    await SaveConversationExchangeAsync(
                        _pendingUserMessage,
                        text,
                        _pendingUserTimestamp.Value
                    );

                    // Clear pending message
                    _pendingUserMessage = null;
                    _pendingUserTimestamp = null;

                    LastMessageReceived = DateTime.Now;
                    MessageCount++;

                    MessageReceived?.Invoke(this, new ConversationMessageEventArgs
                    {
                        IsUser = false,
                        Message = text,
                        Timestamp = DateTime.Now
                    });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error handling assistant message: {ex.Message}");
            }
        }

        private void HandleConversationStart(string payload)
        {
            Console.WriteLine("🆕 New conversation started");

            // Create new conversation file
            var timestamp = DateTime.Now;
            var dateString = timestamp.ToString("yyyy-MM-dd_HHmmss");
            var personalitySlug = _currentPersonality.ToLower().Replace(" ", "_");

            var filename = $"moxie_{personalitySlug}_{dateString}.jsonl";
            _currentConversationFile = Path.Combine(_conversationsDir, filename);

            // Create empty file
            File.WriteAllText(_currentConversationFile, "");

            Console.WriteLine($"📝 Created conversation file: {filename}");
        }

        private void HandleConversationMetadata(string payload)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var json = JsonSerializer.Deserialize<Dictionary<string, object>>(payload, options);

                if (json != null)
                {
                    if (json.ContainsKey("personality"))
                    {
                        _currentPersonality = json["personality"].ToString();
                        Console.WriteLine($"🎭 Personality: {_currentPersonality}");
                    }

                    if (json.ContainsKey("personality_emoji"))
                    {
                        _currentPersonalityEmoji = json["personality_emoji"].ToString();
                        Console.WriteLine($"😀 Emoji: {_currentPersonalityEmoji}");
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error handling conversation metadata: {ex.Message}");
            }
        }

        private async Task SaveConversationExchangeAsync(string user, string assistant, DateTime timestamp)
        {
            // Use current conversation file or create a default one
            if (string.IsNullOrEmpty(_currentConversationFile))
            {
                HandleConversationStart("{}");
            }

            var entry = new Dictionary<string, object>
            {
                ["timestamp"] = timestamp.ToString("o"),
                ["user"] = user,
                ["moxie"] = assistant,
                ["personality"] = _currentPersonality,
                ["personality_emoji"] = _currentPersonalityEmoji
            };

            try
            {
                var jsonString = JsonSerializer.Serialize(entry);

                // Append to file
                await File.AppendAllTextAsync(_currentConversationFile, jsonString + "\n");

                Console.WriteLine($"💾 Saved conversation exchange to {Path.GetFileName(_currentConversationFile)}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to save conversation: {ex.Message}");
            }
        }
    }

    // MARK: - Event Args

    public class ConversationMessageEventArgs : EventArgs
    {
        public bool IsUser { get; set; }
        public string Message { get; set; }
        public DateTime Timestamp { get; set; }
    }

    // MARK: - Interface

    public interface IConversationListenerService
    {
        bool IsListening { get; }
        DateTime? LastMessageReceived { get; }
        int MessageCount { get; }

        event EventHandler<ConversationMessageEventArgs> MessageReceived;

        Task StartListeningAsync();
        Task StopListeningAsync();
    }
}
