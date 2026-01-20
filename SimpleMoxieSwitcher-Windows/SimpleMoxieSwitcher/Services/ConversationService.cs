using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for managing conversation persistence and export
    /// </summary>
    public class ConversationService : IConversationService
    {
        private readonly IDockerService _dockerService;
        private readonly string _deviceId = "moxie_001";
        private readonly string _conversationsPath;

        public ConversationService(IDockerService dockerService)
        {
            _dockerService = dockerService;

            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var appFolder = Path.Combine(appData, "SimpleMoxieSwitcher");
            Directory.CreateDirectory(appFolder);
            _conversationsPath = Path.Combine(appFolder, "conversations.json");
        }

        // MARK: - Load Conversations

        /// <summary>
        /// Load all conversations from local storage and database
        /// </summary>
        public async Task<List<Conversation>> LoadConversationsAsync()
        {
            // Try loading from database first
            try
            {
                var dbConversations = await LoadFromDatabaseAsync();
                if (dbConversations.Any())
                {
                    SaveLocalConversations(dbConversations);
                    return dbConversations;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to load from database: {ex.Message}");
            }

            // Fallback to local file
            return LoadLocalConversations();
        }

        // MARK: - Save Conversation

        /// <summary>
        /// Save a conversation to both local storage and database
        /// </summary>
        public async Task SaveConversationAsync(Conversation conversation)
        {
            // Load existing conversations
            var conversations = LoadLocalConversations();

            // Update or add conversation
            var existing = conversations.FirstOrDefault(c => c.Id == conversation.Id);
            if (existing != null)
            {
                conversations.Remove(existing);
            }
            conversations.Add(conversation);

            // Sort by date (newest first)
            conversations = conversations.OrderByDescending(c => c.Timestamp).ToList();

            // Save locally
            SaveLocalConversations(conversations);

            // Save to database
            await SaveToDatabaseAsync(conversation);

            Console.WriteLine($"💾 Conversation saved: {conversation.Title}");
        }

        // MARK: - Delete Conversation

        /// <summary>
        /// Delete a conversation from local storage and database
        /// </summary>
        public async Task DeleteConversationAsync(Conversation conversation)
        {
            // Remove from local file
            var conversations = LoadLocalConversations();
            conversations.RemoveAll(c => c.Id == conversation.Id);
            SaveLocalConversations(conversations);

            // Remove from database
            await DeleteFromDatabaseAsync(conversation.Id);

            Console.WriteLine($"🗑️ Conversation deleted: {conversation.Title}");
        }

        // MARK: - Export Conversation

        /// <summary>
        /// Export a conversation to a formatted text string
        /// </summary>
        public string ExportConversation(Conversation conversation)
        {
            var sb = new StringBuilder();

            sb.AppendLine($"Conversation: {conversation.Title}");
            sb.AppendLine($"Date: {conversation.FormattedDate}");
            sb.AppendLine($"Personality: {conversation.Personality}");
            sb.AppendLine($"Messages: {conversation.Messages.Count}");
            sb.AppendLine("---");
            sb.AppendLine();

            foreach (var message in conversation.Messages)
            {
                var sender = message.IsUser ? "User" : "Moxie";
                sb.AppendLine($"[{message.FormattedTime}] {sender}: {message.Content}");
                sb.AppendLine();
            }

            return sb.ToString();
        }

        // MARK: - Search Conversations

        /// <summary>
        /// Search conversations by keyword
        /// </summary>
        public async Task<List<Conversation>> SearchConversationsAsync(string keyword)
        {
            var conversations = await LoadConversationsAsync();
            var lowerKeyword = keyword.ToLower();

            return conversations.Where(c =>
                c.Title.ToLower().Contains(lowerKeyword) ||
                c.Messages.Any(m => m.Content.ToLower().Contains(lowerKeyword))
            ).ToList();
        }

        // MARK: - Get Recent Conversations

        /// <summary>
        /// Get the most recent conversations
        /// </summary>
        public async Task<List<Conversation>> GetRecentConversationsAsync(int limit = 10)
        {
            var conversations = await LoadConversationsAsync();
            return conversations.OrderByDescending(c => c.Timestamp).Take(limit).ToList();
        }

        // MARK: - Private Helpers - Local Storage

        private List<Conversation> LoadLocalConversations()
        {
            if (!File.Exists(_conversationsPath))
            {
                return new List<Conversation>();
            }

            try
            {
                var json = File.ReadAllText(_conversationsPath);
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                return JsonSerializer.Deserialize<List<Conversation>>(json, options) ?? new List<Conversation>();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to load local conversations: {ex.Message}");
                return new List<Conversation>();
            }
        }

        private void SaveLocalConversations(List<Conversation> conversations)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                };
                var json = JsonSerializer.Serialize(conversations, options);
                File.WriteAllText(_conversationsPath, json);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to save local conversations: {ex.Message}");
            }
        }

        // MARK: - Private Helpers - Database

        private async Task<List<Conversation>> LoadFromDatabaseAsync()
        {
            var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist = PersistentData.objects.filter(device=device).first()
    if persist and persist.data:
        conversations = persist.data.get('conversations', [])
        print(json.dumps(conversations))
    else:
        print('[]')
else:
    print('[]')
";

            var result = await _dockerService.ExecutePythonScriptAsync(script);

            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            return JsonSerializer.Deserialize<List<Conversation>>(result, options) ?? new List<Conversation>();
        }

        private async Task SaveToDatabaseAsync(Conversation conversation)
        {
            var conversationJSON = JsonSerializer.Serialize(conversation, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });

            var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist, created = PersistentData.objects.get_or_create(
        device=device,
        defaults={{'data': {{}}}}
    )
    data = persist.data or {{}}

    if 'conversations' not in data:
        data['conversations'] = []

    # Find and update or append
    conversation_data = {conversationJSON}
    conversations = data['conversations']
    existing_index = next((i for i, c in enumerate(conversations) if c.get('id') == conversation_data['id']), None)

    if existing_index is not None:
        conversations[existing_index] = conversation_data
    else:
        conversations.append(conversation_data)

    # Keep only last 100 conversations
    if len(conversations) > 100:
        conversations = conversations[-100:]

    data['conversations'] = conversations
    persist.data = data
    persist.save()
    print('Conversation saved to database')
";

            try
            {
                await _dockerService.ExecutePythonScriptAsync(script);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to save conversation to database: {ex.Message}");
            }
        }

        private async Task DeleteFromDatabaseAsync(string conversationId)
        {
            var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist = PersistentData.objects.filter(device=device).first()
    if persist and persist.data:
        data = persist.data or {{}}
        if 'conversations' in data:
            data['conversations'] = [c for c in data['conversations'] if c.get('id') != '{conversationId}']
            persist.data = data
            persist.save()
            print('Conversation deleted from database')
";

            try
            {
                await _dockerService.ExecutePythonScriptAsync(script);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to delete conversation from database: {ex.Message}");
            }
        }
    }

    // MARK: - Interface

    public interface IConversationService
    {
        Task<List<Conversation>> LoadConversationsAsync();
        Task SaveConversationAsync(Conversation conversation);
        Task DeleteConversationAsync(Conversation conversation);
        string ExportConversation(Conversation conversation);
        Task<List<Conversation>> SearchConversationsAsync(string keyword);
        Task<List<Conversation>> GetRecentConversationsAsync(int limit = 10);
    }
}
