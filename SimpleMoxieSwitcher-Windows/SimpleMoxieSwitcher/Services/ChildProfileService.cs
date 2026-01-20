using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for managing child profile persistence and retrieval
    /// </summary>
    public class ChildProfileService : IChildProfileService
    {
        private readonly IDockerService _dockerService;
        private readonly string _deviceId = "moxie_001";
        private readonly string _profilePath;

        public ChildProfile CurrentProfile { get; private set; }

        public ChildProfileService(IDockerService dockerService)
        {
            _dockerService = dockerService;

            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var appFolder = Path.Combine(appData, "SimpleMoxieSwitcher");
            Directory.CreateDirectory(appFolder);
            _profilePath = Path.Combine(appFolder, "child_profile.json");

            // Load cached profile on initialization
            LoadActiveProfile();
        }

        // MARK: - Load Active Profile (Synchronous)

        /// <summary>
        /// Load the currently active profile from local file or in-memory cache
        /// </summary>
        public ChildProfile LoadActiveProfile()
        {
            // First check in-memory cache
            if (CurrentProfile != null)
            {
                return CurrentProfile;
            }

            // Then check local file
            if (!File.Exists(_profilePath))
            {
                return null;
            }

            try
            {
                var json = File.ReadAllText(_profilePath);
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                CurrentProfile = JsonSerializer.Deserialize<ChildProfile>(json, options);
                return CurrentProfile;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to load child profile from local file: {ex.Message}");
                return null;
            }
        }

        // MARK: - Load Profile

        /// <summary>
        /// Load the child profile from the database
        /// </summary>
        public async Task<ChildProfile> LoadProfileAsync()
        {
            var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist = PersistentData.objects.filter(device=device).first()
    if persist and persist.data:
        profile_data = persist.data.get('child_profile')
        if profile_data:
            print(json.dumps(profile_data))
        else:
            print('null')
    else:
        print('null')
else:
    print('null')
";

            var result = await _dockerService.ExecutePythonScriptAsync(script);

            // Check for null result
            var trimmed = result.Trim();
            if (trimmed == "null" || string.IsNullOrEmpty(trimmed))
            {
                return null;
            }

            // Parse JSON response
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            var profile = JsonSerializer.Deserialize<ChildProfile>(trimmed, options);
            CurrentProfile = profile;

            // Save to local cache
            SaveLocalProfile(profile);

            return profile;
        }

        // MARK: - Save Profile

        /// <summary>
        /// Save or update the child profile in the database
        /// </summary>
        public async Task SaveProfileAsync(ChildProfile profile)
        {
            // Update timestamp
            profile.UpdatedAt = DateTime.Now;

            // Encode to JSON
            var options = new JsonSerializerOptions
            {
                WriteIndented = false,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };
            var profileJSON = JsonSerializer.Serialize(profile, options);

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
    data['child_profile'] = {profileJSON}
    persist.data = data
    persist.save()
    print(json.dumps({{'success': True}}))
else:
    print(json.dumps({{'success': False, 'error': 'Device not found'}}))
";

            var result = await _dockerService.ExecutePythonScriptAsync(script);

            // Verify success
            var responseOptions = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            var response = JsonSerializer.Deserialize<Dictionary<string, object>>(result, responseOptions);

            if (response == null || !response.ContainsKey("success") || !(bool)response["success"])
            {
                throw new Exception("Failed to save profile to database");
            }

            CurrentProfile = profile;

            // Also save to local file for synchronous access
            SaveLocalProfile(profile);
        }

        // MARK: - Update Interests

        /// <summary>
        /// Extract and add interests from conversation content
        /// </summary>
        public async Task ExtractAndAddInterestsAsync(string conversationText)
        {
            if (CurrentProfile == null) return;

            // Simple keyword extraction
            var keywords = ExtractKeywords(conversationText);

            // Add new interests (avoid duplicates)
            foreach (var keyword in keywords)
            {
                if (!CurrentProfile.Interests.Contains(keyword))
                {
                    CurrentProfile.Interests.Add(keyword);
                }
            }

            // Save updated profile
            await SaveProfileAsync(CurrentProfile);
        }

        // MARK: - Private Helpers

        private void SaveLocalProfile(ChildProfile profile)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                };
                var json = JsonSerializer.Serialize(profile, options);
                File.WriteAllText(_profilePath, json);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to save local profile: {ex.Message}");
            }
        }

        private List<string> ExtractKeywords(string text)
        {
            // Define interest categories
            var interestPatterns = new Dictionary<string, List<string>>
            {
                ["animals"] = new List<string> { "dog", "cat", "bird", "fish", "dinosaur", "animals", "pets" },
                ["sports"] = new List<string> { "soccer", "basketball", "football", "swimming", "tennis", "sports" },
                ["art"] = new List<string> { "drawing", "painting", "coloring", "art", "crafts" },
                ["music"] = new List<string> { "music", "singing", "piano", "guitar", "drums" },
                ["science"] = new List<string> { "space", "planets", "stars", "robots", "experiments", "science" },
                ["reading"] = new List<string> { "books", "reading", "stories" },
                ["games"] = new List<string> { "games", "puzzles", "lego", "blocks" },
                ["nature"] = new List<string> { "trees", "flowers", "plants", "garden", "nature" },
                ["technology"] = new List<string> { "computer", "iPad", "tablet", "coding", "programming" }
            };

            var foundInterests = new HashSet<string>();
            var lowercasedText = text.ToLower();

            foreach (var (category, patterns) in interestPatterns)
            {
                foreach (var pattern in patterns)
                {
                    if (lowercasedText.Contains(pattern))
                    {
                        foundInterests.Add(category);
                        break;
                    }
                }
            }

            return foundInterests.ToList();
        }

        // MARK: - Get Context for AI

        /// <summary>
        /// Get child profile context formatted for AI prompts
        /// </summary>
        public string GetContextForAI()
        {
            if (CurrentProfile == null)
            {
                return "";
            }
            return CurrentProfile.ContextForAI;
        }
    }

    public interface IChildProfileService
    {
        ChildProfile CurrentProfile { get; }
        ChildProfile LoadActiveProfile();
        Task<ChildProfile> LoadProfileAsync();
        Task SaveProfileAsync(ChildProfile profile);
        Task ExtractAndAddInterestsAsync(string conversationText);
        string GetContextForAI();
    }
}
