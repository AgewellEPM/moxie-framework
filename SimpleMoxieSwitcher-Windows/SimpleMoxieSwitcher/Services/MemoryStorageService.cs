using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for storing and retrieving conversation memories
    /// </summary>
    public class MemoryStorageService : IMemoryStorageService
    {
        private readonly IDockerService _dockerService;
        private readonly string _deviceId = "moxie_001";

        public MemoryStorageService(IDockerService dockerService)
        {
            _dockerService = dockerService;
        }

        // MARK: - Save Memories

        /// <summary>
        /// Save extracted memories to the database
        /// </summary>
        public async Task SaveMemoriesAsync(List<ConversationMemory> memories)
        {
            // Convert memories to JSON
            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };
            var memoriesJSON = JsonSerializer.Serialize(memories, options);

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

    # Get existing memories or initialize
    memories = data.get('extracted_memories', [])

    # Add new memories
    new_memories = {memoriesJSON}
    memories.extend(new_memories)

    # Store back
    data['extracted_memories'] = memories
    persist.data = data
    persist.save()

    print(json.dumps({{'success': True, 'total_memories': len(memories)}}))
else:
    print(json.dumps({{'success': False, 'error': 'Device not found'}}))
";

            var result = await _dockerService.ExecutePythonScriptAsync(script);
            Console.WriteLine($"💾 Saved memories: {result}");
        }

        /// <summary>
        /// Load all memories from the database
        /// </summary>
        public async Task<List<ConversationMemory>> LoadMemoriesAsync()
        {
            var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist = PersistentData.objects.filter(device=device).first()
    if persist and persist.data:
        memories = persist.data.get('extracted_memories', [])
        print(json.dumps(memories))
    else:
        print('[]')
else:
    print('[]')
";

            var result = await _dockerService.ExecutePythonScriptAsync(script);

            // Parse JSON
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            return JsonSerializer.Deserialize<List<ConversationMemory>>(result, options) ?? new List<ConversationMemory>();
        }

        // MARK: - Save Frontal Cortex

        /// <summary>
        /// Save the frontal cortex (core knowledge base)
        /// </summary>
        public async Task SaveFrontalCortexAsync(FrontalCortex cortex)
        {
            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };
            var cortexJSON = JsonSerializer.Serialize(cortex, options);

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
    data['frontal_cortex'] = {cortexJSON}
    persist.data = data
    persist.save()
    print(json.dumps({{'success': True}}))
else:
    print(json.dumps({{'success': False, 'error': 'Device not found'}}))
";

            var result = await _dockerService.ExecutePythonScriptAsync(script);
            Console.WriteLine($"🧠 Saved frontal cortex: {result}");
        }

        /// <summary>
        /// Load the frontal cortex
        /// </summary>
        public async Task<FrontalCortex> LoadFrontalCortexAsync()
        {
            var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist = PersistentData.objects.filter(device=device).first()
    if persist and persist.data:
        cortex = persist.data.get('frontal_cortex')
        if cortex:
            print(json.dumps(cortex))
        else:
            print('null')
    else:
        print('null')
else:
    print('null')
";

            var result = await _dockerService.ExecutePythonScriptAsync(script);

            // Check for null
            var trimmed = result.Trim();
            if (trimmed == "null" || string.IsNullOrEmpty(trimmed))
            {
                return null;
            }

            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            return JsonSerializer.Deserialize<FrontalCortex>(result, options);
        }

        // MARK: - Query Memories

        /// <summary>
        /// Search memories based on query parameters
        /// </summary>
        public async Task<List<MemorySearchResult>> QueryMemoriesAsync(MemoryQuery query)
        {
            // Load all memories
            var allMemories = await LoadMemoriesAsync();

            // Filter by time range
            var filtered = allMemories;
            if (query.TimeRange != null)
            {
                filtered = filtered.Where(memory =>
                    memory.Timestamp >= query.TimeRange.Start &&
                    memory.Timestamp <= query.TimeRange.End
                ).ToList();
            }

            // Filter by memory types
            if (query.MemoryTypes != null && query.MemoryTypes.Any())
            {
                filtered = filtered.Where(memory =>
                    query.MemoryTypes.Contains(memory.MemoryType)
                ).ToList();
            }

            // Filter by importance
            filtered = filtered.Where(m => m.Importance >= query.MinImportance).ToList();

            // Calculate relevance and recency scores
            var now = DateTime.Now;
            var results = new List<MemorySearchResult>();

            foreach (var memory in filtered)
            {
                // Calculate relevance score based on keywords
                var relevanceScore = CalculateRelevanceScore(memory, query.Keywords);

                // Calculate recency score (exponential decay)
                var daysSince = (now - memory.Timestamp).TotalDays;
                var recencyScore = Math.Exp(-daysSince / 30.0); // Decay over 30 days

                var result = new MemorySearchResult
                {
                    Memory = memory,
                    RelevanceScore = relevanceScore,
                    RecencyScore = recencyScore
                };
                results.Add(result);
            }

            // Sort by combined score
            results = results.OrderByDescending(r => r.CombinedScore).ToList();

            // Limit results
            return results.Take(query.Limit).ToList();
        }

        private double CalculateRelevanceScore(ConversationMemory memory, List<string> keywords)
        {
            if (keywords == null || !keywords.Any())
            {
                return 1.0;
            }

            var lowerContent = memory.Content.ToLower();
            var lowerTopics = memory.Topics.Select(t => t.ToLower()).ToList();
            var lowerEntities = memory.Entities.Select(e => e.ToLower()).ToList();

            int matches = 0;
            foreach (var keyword in keywords)
            {
                var lowerKeyword = keyword.ToLower();

                if (lowerContent.Contains(lowerKeyword))
                {
                    matches += 3; // Content match is most important
                }
                if (lowerTopics.Contains(lowerKeyword))
                {
                    matches += 2; // Topic match
                }
                if (lowerEntities.Contains(lowerKeyword))
                {
                    matches += 1; // Entity match
                }
            }

            // Normalize score
            int maxPossibleMatches = keywords.Count * 3;
            return (double)matches / maxPossibleMatches;
        }

        // MARK: - Context Generation

        /// <summary>
        /// Generate AI context from relevant memories
        /// </summary>
        public async Task<string> GenerateContextForAIAsync(List<string> keywords, int limit = 5)
        {
            // Query relevant memories
            var query = new MemoryQuery
            {
                Keywords = keywords,
                TimeRange = null,
                MemoryTypes = new List<MemoryType>(),
                MinImportance = 0.5,
                Limit = limit
            };

            var results = await QueryMemoriesAsync(query);

            if (!results.Any())
            {
                return "";
            }

            var context = "## Relevant Past Conversations\n\n";

            for (int i = 0; i < results.Count; i++)
            {
                var memory = results[i].Memory;
                context += $"{i + 1}. [{memory.MemoryType}] {memory.Content}\n";

                if (memory.Topics != null && memory.Topics.Any())
                {
                    context += $"   Topics: {string.Join(", ", memory.Topics)}\n";
                }

                // Add timestamp for context
                var timeAgo = GetRelativeTimeString(memory.Timestamp);
                context += $"   ({timeAgo})\n\n";
            }

            return context;
        }

        private string GetRelativeTimeString(DateTime timestamp)
        {
            var timeSpan = DateTime.Now - timestamp;

            if (timeSpan.TotalMinutes < 1)
                return "just now";
            if (timeSpan.TotalMinutes < 60)
                return $"{(int)timeSpan.TotalMinutes} minutes ago";
            if (timeSpan.TotalHours < 24)
                return $"{(int)timeSpan.TotalHours} hours ago";
            if (timeSpan.TotalDays < 7)
                return $"{(int)timeSpan.TotalDays} days ago";
            if (timeSpan.TotalDays < 30)
                return $"{(int)(timeSpan.TotalDays / 7)} weeks ago";
            if (timeSpan.TotalDays < 365)
                return $"{(int)(timeSpan.TotalDays / 30)} months ago";

            return $"{(int)(timeSpan.TotalDays / 365)} years ago";
        }
    }

    // MARK: - Supporting Models

    public class MemoryQuery
    {
        public List<string> Keywords { get; set; } = new();
        public DateTimeRange TimeRange { get; set; }
        public List<MemoryType> MemoryTypes { get; set; } = new();
        public double MinImportance { get; set; } = 0.0;
        public int Limit { get; set; } = 10;
    }

    public class DateTimeRange
    {
        public DateTime Start { get; set; }
        public DateTime End { get; set; }
    }

    public class MemorySearchResult
    {
        public ConversationMemory Memory { get; set; }
        public double RelevanceScore { get; set; }
        public double RecencyScore { get; set; }

        public double CombinedScore => (RelevanceScore * 0.7) + (RecencyScore * 0.3);
    }

    // MARK: - Interface

    public interface IMemoryStorageService
    {
        Task SaveMemoriesAsync(List<ConversationMemory> memories);
        Task<List<ConversationMemory>> LoadMemoriesAsync();
        Task SaveFrontalCortexAsync(FrontalCortex cortex);
        Task<FrontalCortex> LoadFrontalCortexAsync();
        Task<List<MemorySearchResult>> QueryMemoriesAsync(MemoryQuery query);
        Task<string> GenerateContextForAIAsync(List<string> keywords, int limit = 5);
    }
}
