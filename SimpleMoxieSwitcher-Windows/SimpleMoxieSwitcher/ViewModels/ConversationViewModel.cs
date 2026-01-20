using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;
using SimpleMoxieSwitcher.Services.Interfaces;

namespace SimpleMoxieSwitcher.ViewModels
{
    public class ConversationViewModel : INotifyPropertyChanged
    {
        private readonly IConversationService _conversationService;
        private readonly IConversationRepository _conversationRepository;
        private readonly IIntentDetectionService _intentDetectionService;

        private ObservableCollection<Conversation> _conversations = new ObservableCollection<Conversation>();
        private bool _isLoading = false;
        private string _errorMessage;
        private SessionState _currentSessionState = new SessionState();
        private string _redirectionSuggestion;

        public ObservableCollection<Conversation> Conversations
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

        public SessionState CurrentSessionState
        {
            get => _currentSessionState;
            set
            {
                _currentSessionState = value;
                OnPropertyChanged();
            }
        }

        public string RedirectionSuggestion
        {
            get => _redirectionSuggestion;
            set
            {
                _redirectionSuggestion = value;
                OnPropertyChanged();
            }
        }

        // Commands
        public ICommand LoadConversationsCommand { get; }
        public ICommand DeleteConversationCommand { get; }
        public ICommand ExportConversationCommand { get; }
        public ICommand StartNewConversationCommand { get; }
        public ICommand AcceptRedirectionCommand { get; }
        public ICommand DismissRedirectionCommand { get; }
        public ICommand StartNewSessionCommand { get; }

        public ConversationViewModel()
        {
            // Initialize services using dependency injection
            _conversationService = DIContainer.Instance.Resolve<IConversationService>();
            _conversationRepository = DIContainer.Instance.Resolve<IConversationRepository>();
            _intentDetectionService = DIContainer.Instance.Resolve<IIntentDetectionService>();

            // Initialize commands
            LoadConversationsCommand = new RelayCommand(async () => await LoadConversations());
            DeleteConversationCommand = new RelayCommand<Conversation>(async (conv) => await DeleteConversation(conv));
            ExportConversationCommand = new RelayCommand<Conversation>(ExportConversation);
            StartNewConversationCommand = new RelayCommand(StartNewConversation);
            AcceptRedirectionCommand = new RelayCommand(AcceptRedirection);
            DismissRedirectionCommand = new RelayCommand(DismissRedirection);
            StartNewSessionCommand = new RelayCommand(StartNewSession);
        }

        public ConversationViewModel(
            IConversationService conversationService,
            IConversationRepository conversationRepository,
            IIntentDetectionService intentDetectionService)
        {
            _conversationService = conversationService;
            _conversationRepository = conversationRepository;
            _intentDetectionService = intentDetectionService;

            // Initialize commands
            LoadConversationsCommand = new RelayCommand(async () => await LoadConversations());
            DeleteConversationCommand = new RelayCommand<Conversation>(async (conv) => await DeleteConversation(conv));
            ExportConversationCommand = new RelayCommand<Conversation>(ExportConversation);
            StartNewConversationCommand = new RelayCommand(StartNewConversation);
            AcceptRedirectionCommand = new RelayCommand(AcceptRedirection);
            DismissRedirectionCommand = new RelayCommand(DismissRedirection);
            StartNewSessionCommand = new RelayCommand(StartNewSession);
        }

        public async Task LoadConversations()
        {
            IsLoading = true;
            ErrorMessage = null;

            try
            {
                var conversations = await _conversationRepository.LoadConversations();
                Conversations.Clear();
                foreach (var conversation in conversations)
                {
                    Conversations.Add(conversation);
                }
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Failed to load conversations: {ex.Message}";
            }

            IsLoading = false;
        }

        public async Task DeleteConversation(Conversation conversation)
        {
            try
            {
                await _conversationRepository.DeleteConversation(conversation);
                await LoadConversations();
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Failed to delete conversation: {ex.Message}";
            }
        }

        public void ExportConversation(Conversation conversation)
        {
            var exported = _conversationService.ExportConversation(conversation);

            // Copy to clipboard (Windows equivalent of NSPasteboard)
            Clipboard.SetText(exported);
        }

        public void StartNewConversation()
        {
            // Open http://localhost:8003/hive/chat/1 in browser to start new conversation
            // (Windows equivalent of NSWorkspace.shared.open)
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "http://localhost:8003/hive/chat/1",
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Failed to open browser: {ex.Message}";
            }
        }

        public List<Conversation> FilterConversations(string searchText)
        {
            if (string.IsNullOrEmpty(searchText))
            {
                return Conversations.ToList();
            }
            else
            {
                return Conversations.Where(conversation =>
                    conversation.Title.Contains(searchText, StringComparison.OrdinalIgnoreCase) ||
                    conversation.PersonalityUsed.Contains(searchText, StringComparison.OrdinalIgnoreCase) ||
                    conversation.Messages.Any(m => m.Content.Contains(searchText, StringComparison.OrdinalIgnoreCase))
                ).ToList();
            }
        }

        // Session Intent Detection
        public void CheckSessionIntent(Conversation conversation)
        {
            CurrentSessionState.IncrementMessages();

            // Only check if it's time
            if (!CurrentSessionState.ShouldRecheckIntent) return;

            var (detectedIntent, confidence) = _intentDetectionService.DetectIntent(conversation.Messages);

            // Check for drift
            if (CurrentSessionState.CurrentIntent.Type != SessionIntentType.Unknown)
            {
                var drift = _intentDetectionService.DetectDrift(
                    CurrentSessionState.CurrentIntent,
                    conversation.Messages.TakeLast(5).ToList()
                );

                CurrentSessionState.DriftDetected = drift;

                if (drift)
                {
                    // Generate redirection suggestion
                    RedirectionSuggestion = _intentDetectionService.GenerateRedirectionSuggestion(
                        CurrentSessionState.CurrentIntent,
                        detectedIntent
                    );
                }
            }

            // Update intent
            CurrentSessionState.UpdateIntent(detectedIntent, confidence);
        }

        public void AcceptRedirection()
        {
            RedirectionSuggestion = null;
            CurrentSessionState.DriftDetected = false;
        }

        public void DismissRedirection()
        {
            RedirectionSuggestion = null;
        }

        public void StartNewSession()
        {
            CurrentSessionState = new SessionState();
            RedirectionSuggestion = null;
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    // Interface definitions for dependency injection
    public interface IConversationService
    {
        string ExportConversation(Conversation conversation);
    }

    public interface IConversationRepository
    {
        Task<List<Conversation>> LoadConversations();
        Task DeleteConversation(Conversation conversation);
    }

    public interface IIntentDetectionService
    {
        (SessionIntent intent, double confidence) DetectIntent(List<ConversationMessage> messages);
        bool DetectDrift(SessionIntent currentIntent, List<ConversationMessage> recentMessages);
        string GenerateRedirectionSuggestion(SessionIntent from, SessionIntent to);
    }
}