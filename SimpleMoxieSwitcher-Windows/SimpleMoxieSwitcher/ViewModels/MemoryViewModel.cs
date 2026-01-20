using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;

namespace SimpleMoxieSwitcher.ViewModels
{
    /// <summary>
    /// ViewModel for managing memory extraction and retrieval
    /// </summary>
    public class MemoryViewModel : INotifyPropertyChanged
    {
        private readonly MemoryExtractionService _memoryExtractionService;
        private readonly MemoryStorageService _memoryStorageService;

        private bool _isExtracting = false;
        private double _extractionProgress = 0.0;
        private string _extractionStatus = "";
        private int _totalMemoriesExtracted = 0;
        private FrontalCortex _frontalCortex;
        private string _errorMessage;

        public bool IsExtracting
        {
            get => _isExtracting;
            set
            {
                _isExtracting = value;
                OnPropertyChanged();
            }
        }

        public double ExtractionProgress
        {
            get => _extractionProgress;
            set
            {
                _extractionProgress = value;
                OnPropertyChanged();
            }
        }

        public string ExtractionStatus
        {
            get => _extractionStatus;
            set
            {
                _extractionStatus = value;
                OnPropertyChanged();
            }
        }

        public int TotalMemoriesExtracted
        {
            get => _totalMemoriesExtracted;
            set
            {
                _totalMemoriesExtracted = value;
                OnPropertyChanged();
            }
        }

        public FrontalCortex FrontalCortex
        {
            get => _frontalCortex;
            set
            {
                _frontalCortex = value;
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
        public ICommand LoadExistingMemoriesCommand { get; }
        public ICommand ExtractMemoriesCommand { get; }

        public MemoryViewModel(
            MemoryExtractionService memoryExtractionService = null,
            MemoryStorageService memoryStorageService = null)
        {
            _memoryExtractionService = memoryExtractionService ?? DIContainer.Instance.Resolve<MemoryExtractionService>();
            _memoryStorageService = memoryStorageService ?? DIContainer.Instance.Resolve<MemoryStorageService>();

            // Initialize commands
            LoadExistingMemoriesCommand = new RelayCommand(async () => await LoadExistingMemories());
            ExtractMemoriesCommand = new RelayCommand<List<ConversationFile>>(async (conversations) =>
                await ExtractMemoriesFromConversations(conversations));
        }

        /// <summary>
        /// Extract memories from all loaded conversations
        /// </summary>
        public async Task ExtractMemoriesFromConversations(List<ConversationFile> conversations)
        {
            IsExtracting = true;
            ExtractionProgress = 0.0;
            TotalMemoriesExtracted = 0;
            ErrorMessage = null;

            try
            {
                // Convert ConversationFile format to expected format
                var allConversations = new List<Dictionary<string, object>>();

                foreach (var conversation in conversations)
                {
                    if (conversation.Messages != null)
                    {
                        allConversations.AddRange(conversation.Messages);
                    }
                }

                ExtractionStatus = $"Extracting memories from {allConversations.Count} conversations...";

                // Extract memories in batches
                const int batchSize = 10;
                var allExtractedMemories = new List<ConversationMemory>();

                var batches = ChunkList(allConversations, batchSize);
                int batchIndex = 0;

                foreach (var batch in batches)
                {
                    ExtractionStatus = $"Processing batch {batchIndex + 1}...";

                    var batchMemories = await _memoryExtractionService.ExtractMemoriesFromBatch(
                        batch,
                        batchIndex * batchSize
                    );

                    allExtractedMemories.AddRange(batchMemories);
                    TotalMemoriesExtracted = allExtractedMemories.Count;

                    // Update progress
                    int processedCount = (batchIndex + 1) * batchSize;
                    ExtractionProgress = Math.Min((double)processedCount / allConversations.Count, 0.9);

                    batchIndex++;
                }

                // Save memories to database
                ExtractionStatus = $"Saving {allExtractedMemories.Count} memories to database...";
                await _memoryStorageService.SaveMemories(allExtractedMemories);

                // Build frontal cortex from memories
                ExtractionStatus = "Building frontal cortex...";
                var cortex = await BuildFrontalCortex(allExtractedMemories);

                // Save frontal cortex
                await _memoryStorageService.SaveFrontalCortex(cortex);
                FrontalCortex = cortex;

                ExtractionProgress = 1.0;
                ExtractionStatus = $"✅ Extraction complete! {TotalMemoriesExtracted} memories extracted";

                System.Diagnostics.Debug.WriteLine($"Memory extraction complete:");
                System.Diagnostics.Debug.WriteLine($"   - Total memories: {TotalMemoriesExtracted}");
                System.Diagnostics.Debug.WriteLine($"   - Frontal cortex saved with {cortex.Interests.Count} interests");
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Failed to extract memories: {ex.Message}";
                ExtractionStatus = "❌ Extraction failed";
                System.Diagnostics.Debug.WriteLine($"Memory extraction error: {ex}");
            }
            finally
            {
                IsExtracting = false;
                ExtractionProgress = 1.0;
            }
        }

        /// <summary>
        /// Build consolidated frontal cortex from extracted memories
        /// </summary>
        private Task<FrontalCortex> BuildFrontalCortex(List<ConversationMemory> memories)
        {
            var cortex = new FrontalCortex { UserId = "moxie_001" };

            // Extract core facts
            var facts = memories.Where(m => m.MemoryType == MemoryType.Fact);
            foreach (var fact in facts)
            {
                var content = fact.Content;
                if (content.ToLower().Contains("user"))
                {
                    var cleaned = content.Replace("User ", "").Replace("user ", "");
                    cortex.CoreFacts[Guid.NewGuid().ToString()] = cleaned;
                }
            }

            // Extract preferences
            var preferences = memories.Where(m => m.MemoryType == MemoryType.Preference);
            foreach (var pref in preferences)
            {
                cortex.Preferences[Guid.NewGuid().ToString()] = pref.Content;
            }

            // Extract relationships
            var relationships = memories.Where(m => m.MemoryType == MemoryType.Relationship);
            foreach (var rel in relationships)
            {
                if (rel.Entities.Any())
                {
                    cortex.Relationships[rel.Entities.First()] = rel.Content;
                }
            }

            // Extract goals
            var goals = memories.Where(m => m.MemoryType == MemoryType.Goal);
            cortex.Goals = goals.Select(g => g.Content).ToList();

            // Extract skills
            var skills = memories.Where(m => m.MemoryType == MemoryType.Skill);
            cortex.Skills = skills.Select(s => s.Content).ToList();

            // Extract interests from topics
            var interestCounts = new Dictionary<string, int>();
            foreach (var memory in memories)
            {
                foreach (var topic in memory.Topics)
                {
                    if (interestCounts.ContainsKey(topic))
                        interestCounts[topic]++;
                    else
                        interestCounts[topic] = 1;
                }
            }

            // Take top interests (mentioned at least 2 times)
            cortex.Interests = interestCounts
                .Where(kvp => kvp.Value >= 2)
                .OrderByDescending(kvp => kvp.Value)
                .Select(kvp => kvp.Key)
                .ToList();

            // Build emotional profile
            var emotions = memories.Where(m => m.MemoryType == MemoryType.Emotion);
            var sentimentCounts = new Dictionary<MemorySentiment, int>();
            var emotionalTriggers = new Dictionary<string, MemorySentiment>();

            foreach (var emotion in emotions)
            {
                if (sentimentCounts.ContainsKey(emotion.Sentiment))
                    sentimentCounts[emotion.Sentiment]++;
                else
                    sentimentCounts[emotion.Sentiment] = 1;

                // Extract triggers from topics
                foreach (var topic in emotion.Topics)
                {
                    emotionalTriggers[topic] = emotion.Sentiment;
                }
            }

            cortex.EmotionalProfile.DominantEmotions = sentimentCounts
                .OrderByDescending(kvp => kvp.Value)
                .Select(kvp => kvp.Key)
                .ToList();
            cortex.EmotionalProfile.EmotionalTriggers = emotionalTriggers;

            // Build conversation patterns
            var topicCounts = new Dictionary<string, int>();
            foreach (var memory in memories)
            {
                foreach (var topic in memory.Topics)
                {
                    if (topicCounts.ContainsKey(topic))
                        topicCounts[topic]++;
                    else
                        topicCounts[topic] = 1;
                }
            }
            cortex.ConversationPatterns.CommonTopics = topicCounts;

            // Calculate average conversation length
            var conversationIds = memories.Select(m => m.ConversationId).Distinct().Count();
            if (conversationIds > 0)
            {
                cortex.ConversationPatterns.AverageConversationLength = memories.Count / conversationIds;
            }

            // Detect question types
            var questions = memories.Where(m => m.MemoryType == MemoryType.Question);
            var questionTypes = new HashSet<string>();
            foreach (var question in questions)
            {
                var content = question.Content.ToLower();
                if (content.Contains("why")) questionTypes.Add("why");
                if (content.Contains("how")) questionTypes.Add("how");
                if (content.Contains("what")) questionTypes.Add("what");
                if (content.Contains("when")) questionTypes.Add("when");
                if (content.Contains("where")) questionTypes.Add("where");
                if (content.Contains("who")) questionTypes.Add("who");
            }
            cortex.ConversationPatterns.QuestionTypes = questionTypes.ToList();

            cortex.LastUpdated = DateTime.Now;

            return Task.FromResult(cortex);
        }

        /// <summary>
        /// Load existing memories and frontal cortex from database
        /// </summary>
        public async Task LoadExistingMemories()
        {
            try
            {
                var memories = await _memoryStorageService.LoadMemories();
                TotalMemoriesExtracted = memories.Count;

                var cortex = await _memoryStorageService.LoadFrontalCortex();
                if (cortex != null)
                {
                    FrontalCortex = cortex;
                    ExtractionStatus = $"Loaded {memories.Count} existing memories";
                }
                else
                {
                    ExtractionStatus = "No existing memories found";
                }
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Failed to load memories: {ex.Message}";
                System.Diagnostics.Debug.WriteLine($"Failed to load memories: {ex}");
            }
        }

        /// <summary>
        /// Generate AI context from relevant memories based on keywords
        /// </summary>
        public async Task<string> GenerateContextForAI(List<string> keywords)
        {
            try
            {
                // Get memory context
                var memoryContext = await _memoryStorageService.GenerateContextForAI(keywords, 5);

                // Get frontal cortex context
                var cortexContext = "";
                if (FrontalCortex != null)
                {
                    cortexContext = FrontalCortex.GenerateContextForAI();
                }

                // Combine both contexts
                if (!string.IsNullOrEmpty(cortexContext) && !string.IsNullOrEmpty(memoryContext))
                {
                    return cortexContext + "\n\n" + memoryContext;
                }
                else if (!string.IsNullOrEmpty(cortexContext))
                {
                    return cortexContext;
                }
                else
                {
                    return memoryContext;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to generate context: {ex}");
                return "";
            }
        }

        /// <summary>
        /// Helper method to chunk a list into batches
        /// </summary>
        private static List<List<T>> ChunkList<T>(List<T> source, int chunkSize)
        {
            var chunks = new List<List<T>>();
            for (int i = 0; i < source.Count; i += chunkSize)
            {
                chunks.Add(source.GetRange(i, Math.Min(chunkSize, source.Count - i)));
            }
            return chunks;
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    /// <summary>
    /// Conversation file model for memory extraction
    /// </summary>
    public class ConversationFile
    {
        public string Id { get; set; }
        public List<Dictionary<string, object>> Messages { get; set; }
        public DateTime Timestamp { get; set; }
        public string Personality { get; set; }
    }
}