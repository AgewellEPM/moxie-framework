using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for extracting memories from conversations using AI and rule-based analysis
    /// </summary>
    public class MemoryExtractionService : IMemoryExtractionService
    {
        private readonly IAIService _aiService;

        public MemoryExtractionService(IAIService aiService)
        {
            _aiService = aiService;
        }

        // MARK: - Extract Memories from Conversation

        /// <summary>
        /// Extract structured memories from a conversation exchange
        /// </summary>
        public async Task<List<ConversationMemory>> ExtractMemoriesAsync(
            Dictionary<string, object> conversation,
            string conversationId)
        {
            if (!conversation.ContainsKey("user") ||
                !conversation.ContainsKey("moxie") ||
                !conversation.ContainsKey("timestamp"))
            {
                return new List<ConversationMemory>();
            }

            var userMessage = conversation["user"].ToString();
            var moxieMessage = conversation["moxie"].ToString();
            var timestampString = conversation["timestamp"].ToString();

            if (!DateTime.TryParse(timestampString, out var timestamp))
            {
                timestamp = DateTime.Now;
            }

            var memories = new List<ConversationMemory>();

            // Use AI to extract structured information
            var extractionPrompt = BuildExtractionPrompt(userMessage, moxieMessage);

            try
            {
                var response = await _aiService.SendMessageAsync(
                    extractionPrompt,
                    Personality.MotivationalCoach,
                    FeatureType.Other,
                    new List<ConversationMessage>()
                );

                // Parse the AI response to extract memories
                memories = ParseMemoryExtractionResponse(
                    response.Content,
                    conversationId,
                    timestamp
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ AI extraction failed, falling back to rule-based extraction: {ex.Message}");

                // Fallback to rule-based extraction
                memories = ExtractMemoriesRuleBased(
                    userMessage,
                    moxieMessage,
                    conversationId,
                    timestamp
                );
            }

            return memories;
        }

        // MARK: - AI-Based Extraction

        private string BuildExtractionPrompt(string userMessage, string moxieMessage)
        {
            return $@"
Analyze this conversation and extract key information:

User: {userMessage}
Moxie: {moxieMessage}

Extract the following information in JSON format:
{{
  ""facts"": [""User stated facts about themselves""],
  ""preferences"": [""User expressed preferences""],
  ""emotions"": [""User expressed emotions""],
  ""topics"": [""Main topics discussed""],
  ""entities"": [""People, places, things mentioned""],
  ""questions"": [""Questions the user asked""],
  ""goals"": [""Goals or aspirations mentioned""]
}}

Only include information that is clearly stated. Return ONLY the JSON, nothing else.
";
        }

        private List<ConversationMemory> ParseMemoryExtractionResponse(
            string response,
            string conversationId,
            DateTime timestamp)
        {
            var memories = new List<ConversationMemory>();

            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var extracted = JsonSerializer.Deserialize<Dictionary<string, List<string>>>(response, options);

                if (extracted == null) return memories;

                // Extract facts
                if (extracted.ContainsKey("facts"))
                {
                    foreach (var fact in extracted["facts"])
                    {
                        memories.Add(new ConversationMemory
                        {
                            ConversationId = conversationId,
                            Timestamp = timestamp,
                            MemoryType = MemoryType.Fact,
                            Content = fact,
                            Entities = new List<string>(),
                            Topics = new List<string>(),
                            Importance = 0.7
                        });
                    }
                }

                // Extract preferences
                if (extracted.ContainsKey("preferences"))
                {
                    foreach (var pref in extracted["preferences"])
                    {
                        memories.Add(new ConversationMemory
                        {
                            ConversationId = conversationId,
                            Timestamp = timestamp,
                            MemoryType = MemoryType.Preference,
                            Content = pref,
                            Entities = new List<string>(),
                            Topics = new List<string>(),
                            Importance = 0.8
                        });
                    }
                }

                // Extract emotions
                if (extracted.ContainsKey("emotions"))
                {
                    foreach (var emotion in extracted["emotions"])
                    {
                        memories.Add(new ConversationMemory
                        {
                            ConversationId = conversationId,
                            Timestamp = timestamp,
                            MemoryType = MemoryType.Emotion,
                            Content = emotion,
                            Entities = new List<string>(),
                            Topics = new List<string>(),
                            Sentiment = DetectSentiment(emotion),
                            Importance = 0.6
                        });
                    }
                }

                // Extract goals
                if (extracted.ContainsKey("goals"))
                {
                    foreach (var goal in extracted["goals"])
                    {
                        memories.Add(new ConversationMemory
                        {
                            ConversationId = conversationId,
                            Timestamp = timestamp,
                            MemoryType = MemoryType.Goal,
                            Content = goal,
                            Entities = new List<string>(),
                            Topics = new List<string>(),
                            Importance = 0.9
                        });
                    }
                }

                // Get topics and entities
                var topics = extracted.ContainsKey("topics") ? extracted["topics"] : new List<string>();
                var entities = extracted.ContainsKey("entities") ? extracted["entities"] : new List<string>();

                // Add to all memories
                foreach (var memory in memories)
                {
                    memory.Topics = topics;
                    memory.Entities = entities;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to parse AI memory extraction: {ex.Message}");
            }

            return memories;
        }

        // MARK: - Rule-Based Extraction (Fallback)

        private List<ConversationMemory> ExtractMemoriesRuleBased(
            string userMessage,
            string moxieMessage,
            string conversationId,
            DateTime timestamp)
        {
            var memories = new List<ConversationMemory>();
            var lowerUser = userMessage.ToLower();

            // Detect preferences
            if (lowerUser.Contains("i like") || lowerUser.Contains("i love") || lowerUser.Contains("i prefer"))
            {
                memories.Add(new ConversationMemory
                {
                    ConversationId = conversationId,
                    Timestamp = timestamp,
                    MemoryType = MemoryType.Preference,
                    Content = userMessage,
                    Topics = ExtractTopics(userMessage),
                    Importance = 0.7
                });
            }

            // Detect emotions
            var emotionKeywords = new[] { "sad", "happy", "angry", "excited", "scared", "worried", "frustrated" };
            foreach (var keyword in emotionKeywords)
            {
                if (lowerUser.Contains(keyword))
                {
                    memories.Add(new ConversationMemory
                    {
                        ConversationId = conversationId,
                        Timestamp = timestamp,
                        MemoryType = MemoryType.Emotion,
                        Content = userMessage,
                        Sentiment = MapKeywordToSentiment(keyword),
                        Importance = 0.6
                    });
                    break;
                }
            }

            // Detect goals
            if (lowerUser.Contains("i want to") || lowerUser.Contains("i need to") || lowerUser.Contains("i hope to"))
            {
                memories.Add(new ConversationMemory
                {
                    ConversationId = conversationId,
                    Timestamp = timestamp,
                    MemoryType = MemoryType.Goal,
                    Content = userMessage,
                    Importance = 0.8
                });
            }

            // Detect relationships
            var relationshipKeywords = new[] { "my mom", "my dad", "my sister", "my brother", "my friend" };
            foreach (var keyword in relationshipKeywords)
            {
                if (lowerUser.Contains(keyword))
                {
                    memories.Add(new ConversationMemory
                    {
                        ConversationId = conversationId,
                        Timestamp = timestamp,
                        MemoryType = MemoryType.Relationship,
                        Content = userMessage,
                        Entities = ExtractNames(userMessage),
                        Importance = 0.9
                    });
                    break;
                }
            }

            return memories;
        }

        // MARK: - Helper Methods

        private MemorySentiment DetectSentiment(string text)
        {
            var lower = text.ToLower();
            var positiveWords = new[] { "happy", "excited", "love", "great", "wonderful", "amazing" };
            var negativeWords = new[] { "sad", "angry", "hate", "terrible", "awful", "scared" };

            int positiveCount = positiveWords.Count(word => lower.Contains(word));
            int negativeCount = negativeWords.Count(word => lower.Contains(word));

            if (positiveCount > negativeCount)
            {
                return MemorySentiment.Positive;
            }
            else if (negativeCount > positiveCount)
            {
                return MemorySentiment.Negative;
            }
            else if (positiveCount > 0 && negativeCount > 0)
            {
                return MemorySentiment.Mixed;
            }
            else
            {
                return MemorySentiment.Neutral;
            }
        }

        private MemorySentiment MapKeywordToSentiment(string keyword)
        {
            return keyword switch
            {
                "happy" or "excited" => MemorySentiment.Positive,
                "sad" or "angry" or "scared" or "worried" or "frustrated" => MemorySentiment.Negative,
                _ => MemorySentiment.Neutral
            };
        }

        private List<string> ExtractTopics(string text)
        {
            var commonTopics = new[]
            {
                "dinosaurs", "space", "animals", "music", "art", "reading", "games",
                "school", "friends", "family", "sports", "food", "nature"
            };

            var lower = text.ToLower();
            return commonTopics.Where(topic => lower.Contains(topic)).ToList();
        }

        private List<string> ExtractNames(string text)
        {
            // Simple name extraction (looks for capitalized words)
            var words = text.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            return words.Where(word =>
            {
                if (string.IsNullOrEmpty(word) || word.Length < 2) return false;
                return char.IsUpper(word[0]);
            }).ToList();
        }

        // MARK: - Batch Processing

        /// <summary>
        /// Process multiple conversations in batch
        /// </summary>
        public async Task<List<ConversationMemory>> ExtractMemoriesFromBatchAsync(
            List<Dictionary<string, object>> conversations,
            int startingId = 0)
        {
            var allMemories = new List<ConversationMemory>();

            for (int index = 0; index < conversations.Count; index++)
            {
                var conversation = conversations[index];
                var conversationId = (startingId + index).ToString();

                try
                {
                    var memories = await ExtractMemoriesAsync(conversation, conversationId);
                    allMemories.AddRange(memories);

                    // Small delay to avoid overwhelming the AI service
                    await Task.Delay(100); // 0.1 seconds
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"⚠️ Failed to extract memories from conversation {conversationId}: {ex.Message}");
                }
            }

            return allMemories;
        }
    }

    // MARK: - Interface

    public interface IMemoryExtractionService
    {
        Task<List<ConversationMemory>> ExtractMemoriesAsync(
            Dictionary<string, object> conversation,
            string conversationId);

        Task<List<ConversationMemory>> ExtractMemoriesFromBatchAsync(
            List<Dictionary<string, object>> conversations,
            int startingId = 0);
    }
}
