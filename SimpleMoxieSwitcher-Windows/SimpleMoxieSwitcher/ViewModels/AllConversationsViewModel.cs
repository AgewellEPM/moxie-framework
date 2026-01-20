using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows.Input;
using System.Windows.Threading;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services.Interfaces;

namespace SimpleMoxieSwitcher.ViewModels
{
    public class AllConversationsViewModel : INotifyPropertyChanged
    {
        private readonly IDockerService _dockerService;
        private DispatcherTimer _refreshTimer;

        private ObservableCollection<ConversationSession> _conversations = new ObservableCollection<ConversationSession>();
        private bool _isLoading = false;
        private string _errorMessage;

        public ObservableCollection<ConversationSession> Conversations
        {
            get => _conversations;
            set
            {
                _conversations = value;
                OnPropertyChanged();
            }
        }

        public bool IsLoading
        {
            get => _isLoading;
            set
            {
                _isLoading = value;
                OnPropertyChanged();
            }
        }

        public string ErrorMessage
        {
            get => _errorMessage;
            set
            {
                _errorMessage = value;
                OnPropertyChanged();
            }
        }

        // Commands
        public ICommand LoadConversationsCommand { get; }
        public ICommand StartAutoRefreshCommand { get; }
        public ICommand StopAutoRefreshCommand { get; }

        public AllConversationsViewModel(IDockerService dockerService)
        {
            _dockerService = dockerService;

            // Initialize commands
            LoadConversationsCommand = new RelayCommand(async () => await LoadConversations());
            StartAutoRefreshCommand = new RelayCommand(StartAutoRefresh);
            StopAutoRefreshCommand = new RelayCommand(StopAutoRefresh);
        }

        public async Task LoadConversations()
        {
            IsLoading = true;
            ErrorMessage = null;

            try
            {
                string pythonScript = @"
from hive.models import MoxieDevice, PersistentData
import json
from datetime import datetime

# Get the device
device = MoxieDevice.objects.filter(device_id='moxie_001').first()
if device:
    persist = PersistentData.objects.filter(device=device).first()
    if persist and persist.data:
        # Get real conversations
        real_convs = persist.data.get('real_conversations', [])

        # Group by date/session
        sessions = {}
        for conv in real_convs:
            # Extract date from timestamp
            timestamp = conv.get('timestamp', '')
            if timestamp:
                try:
                    dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                    session_key = f""{dt.strftime('%Y-%m-%d_%H')}""

                    if session_key not in sessions:
                        sessions[session_key] = {
                            'id': session_key,
                            'personality': conv.get('personality', 'Default'),
                            'timestamp': timestamp,
                            'messages': []
                        }

                    # Add both user and moxie messages
                    if conv.get('user'):
                        sessions[session_key]['messages'].append({
                            'role': 'user',
                            'content': conv['user'],
                            'timestamp': timestamp
                        })
                    if conv.get('moxie'):
                        sessions[session_key]['messages'].append({
                            'role': 'moxie',
                            'content': conv['moxie'],
                            'timestamp': timestamp
                        })
                except:
                    pass

        # Convert to list and sort by timestamp
        session_list = list(sessions.values())
        session_list.sort(key=lambda x: x['timestamp'], reverse=True)

        # Output as JSON
        print(json.dumps(session_list))
    else:
        print(json.dumps([]))
else:
    print(json.dumps([]))
";

                var output = await _dockerService.ExecutePythonScript(pythonScript);

                // Parse the JSON output
                if (!string.IsNullOrEmpty(output))
                {
                    try
                    {
                        var sessionsArray = JsonSerializer.Deserialize<List<ConversationSessionData>>(output);

                        if (sessionsArray != null)
                        {
                            // Convert to our model
                            var conversations = sessionsArray.Select(sessionData =>
                            {
                                var messages = sessionData.Messages.Select(msg => new ChatMessage
                                {
                                    Role = msg.Role,
                                    Content = msg.Content,
                                    Timestamp = DateTime.TryParse(msg.Timestamp, out var dt) ? dt : DateTime.Now
                                }).ToList();

                                return new ConversationSession
                                {
                                    Id = sessionData.Id,
                                    Personality = sessionData.Personality,
                                    Timestamp = DateTime.TryParse(sessionData.Timestamp, out var dt) ? dt : DateTime.Now,
                                    Messages = messages,
                                    MessageCount = messages.Count
                                };
                            }).ToList();

                            // Update ObservableCollection
                            Conversations.Clear();
                            foreach (var conv in conversations)
                            {
                                Conversations.Add(conv);
                            }
                        }
                        else
                        {
                            Conversations.Clear();
                        }
                    }
                    catch (JsonException ex)
                    {
                        ErrorMessage = $"Failed to parse conversation data: {ex.Message}";
                        Conversations.Clear();
                    }
                }
                else
                {
                    // No real conversations yet
                    Conversations.Clear();
                }
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Failed to load conversations: {ex.Message}";
                Conversations.Clear();
            }

            IsLoading = false;
        }

        public void StartAutoRefresh()
        {
            // Refresh every 5 seconds to show new conversations
            _refreshTimer = new DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(5)
            };
            _refreshTimer.Tick += async (sender, e) => await LoadConversations();
            _refreshTimer.Start();
        }

        public void StopAutoRefresh()
        {
            _refreshTimer?.Stop();
            _refreshTimer = null;
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        // Dispose pattern for timer cleanup
        public void Dispose()
        {
            _refreshTimer?.Stop();
            _refreshTimer = null;
        }
    }

    // Data structures for JSON parsing
    public class ConversationSessionData
    {
        public string Id { get; set; }
        public string Personality { get; set; }
        public string Timestamp { get; set; }
        public List<MessageData> Messages { get; set; }
    }

    public class MessageData
    {
        public string Role { get; set; }
        public string Content { get; set; }
        public string Timestamp { get; set; }
    }

    // Model for conversation sessions
    public class ConversationSession
    {
        public string Id { get; set; }
        public string Personality { get; set; }
        public DateTime Timestamp { get; set; }
        public List<ChatMessage> Messages { get; set; }
        public int MessageCount { get; set; }

        public string Preview
        {
            get
            {
                var firstUserMessage = Messages?.FirstOrDefault(m => m.Role == "user");
                if (firstUserMessage != null)
                {
                    var preview = firstUserMessage.Content;
                    return preview.Length > 100 ? preview.Substring(0, 100) + "..." : preview;
                }
                return "No messages";
            }
        }

        public string FormattedDate
        {
            get
            {
                return Timestamp.ToString("MMM dd, yyyy h:mm tt");
            }
        }
    }

    public class ChatMessage
    {
        public string Role { get; set; }
        public string Content { get; set; }
        public DateTime Timestamp { get; set; }
    }
}