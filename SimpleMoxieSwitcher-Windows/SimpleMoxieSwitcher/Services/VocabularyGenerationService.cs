using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for generating language learning vocabulary using AI
    /// </summary>
    public class VocabularyGenerationService : IVocabularyGenerationService
    {
        private readonly IAIService _aiService;
        private readonly IChildProfileService _childProfileService;

        public VocabularyGenerationService(IAIService aiService, IChildProfileService childProfileService)
        {
            _aiService = aiService;
            _childProfileService = childProfileService;
        }

        // MARK: - Helper Methods

        private string GetChildContext()
        {
            var profile = _childProfileService.LoadActiveProfile();
            if (profile == null)
            {
                return "";
            }

            var context = "\n\nPERSONALIZATION CONTEXT:\n";
            context += "The learner:\n";
            context += $"- Name: {profile.Name}\n";

            if (profile.Age.HasValue)
            {
                context += $"- Age: {profile.Age} years old\n";
            }

            if (profile.Interests != null && profile.Interests.Any())
            {
                context += $"- Interests: {string.Join(", ", profile.Interests)}\n";
            }

            context += "\nPlease select vocabulary and examples that will be especially engaging and relevant for this learner.\n";

            return context;
        }

        // MARK: - Vocabulary Generation

        /// <summary>
        /// Generate essential vocabulary for a given language and proficiency level
        /// </summary>
        public async Task<List<VocabularyWord>> GenerateEssentialVocabularyAsync(
            string language,
            string languageCode,
            ProficiencyLevel proficiencyLevel,
            int count = 50)
        {
            var difficulty = GetLevelDescription(proficiencyLevel);
            var childContext = GetChildContext();

            var prompt = $@"
Generate {count} essential vocabulary words for learning {language} at the {difficulty} level.

Return ONLY a JSON array of vocabulary items in this exact format:
[
  {{
    ""word"": ""native word"",
    ""translation"": ""English translation"",
    ""pronunciation"": ""phonetic pronunciation"",
    ""partOfSpeech"": ""noun/verb/adjective/etc"",
    ""exampleSentence"": ""example using the word in {language}"",
    ""exampleTranslation"": ""English translation of example""
  }}
]

Focus on the most commonly used and practical words for everyday communication.
Include a good mix of nouns, verbs, and adjectives.
Make sure pronunciations are accurate and helpful for English speakers.
{childContext}
";

            var response = await _aiService.SendMessageAsync(
                prompt,
                Personality.MotivationalCoach,
                FeatureType.Learning,
                new List<ConversationMessage>()
            );

            return ParseVocabularyJSON(response.Content);
        }

        /// <summary>
        /// Generate vocabulary related to specific interests
        /// </summary>
        public async Task<List<VocabularyWord>> GenerateInterestVocabularyAsync(
            string language,
            string languageCode,
            string interest,
            ProficiencyLevel proficiencyLevel,
            int count = 30)
        {
            var difficulty = GetLevelDescription(proficiencyLevel);
            var childContext = GetChildContext();

            var prompt = $@"
Generate {count} vocabulary words in {language} related to ""{interest}"" at the {difficulty} level.

Return ONLY a JSON array of vocabulary items in this exact format:
[
  {{
    ""word"": ""native word"",
    ""translation"": ""English translation"",
    ""pronunciation"": ""phonetic pronunciation"",
    ""partOfSpeech"": ""noun/verb/adjective/etc"",
    ""exampleSentence"": ""example using the word in {language}"",
    ""exampleTranslation"": ""English translation of example""
  }}
]

Focus on vocabulary specific to {interest} that would be useful and engaging.
Include verbs, nouns, and descriptive words relevant to this topic.
{childContext}
";

            var response = await _aiService.SendMessageAsync(
                prompt,
                Personality.MotivationalCoach,
                FeatureType.Learning,
                new List<ConversationMessage>()
            );

            return ParseVocabularyJSON(response.Content);
        }

        /// <summary>
        /// Generate travel-specific vocabulary
        /// </summary>
        public async Task<List<VocabularyWord>> GenerateTravelVocabularyAsync(
            string language,
            string languageCode,
            ProficiencyLevel proficiencyLevel)
        {
            var difficulty = GetLevelDescription(proficiencyLevel);
            var childContext = GetChildContext();

            var prompt = $@"
Generate 40 essential travel vocabulary words and phrases in {language} at the {difficulty} level.

Include words/phrases for:
- Airport and transportation
- Hotels and accommodation
- Restaurants and food ordering
- Shopping and money
- Emergency situations
- Asking for directions

Return ONLY a JSON array of vocabulary items in this exact format:
[
  {{
    ""word"": ""native word or phrase"",
    ""translation"": ""English translation"",
    ""pronunciation"": ""phonetic pronunciation"",
    ""partOfSpeech"": ""phrase/noun/verb/etc"",
    ""exampleSentence"": ""example situation in {language}"",
    ""exampleTranslation"": ""English translation of example""
  }}
]
{childContext}
";

            var response = await _aiService.SendMessageAsync(
                prompt,
                Personality.MotivationalCoach,
                FeatureType.Learning,
                new List<ConversationMessage>()
            );

            return ParseVocabularyJSON(response.Content);
        }

        /// <summary>
        /// Generate business/professional vocabulary
        /// </summary>
        public async Task<List<VocabularyWord>> GenerateBusinessVocabularyAsync(
            string language,
            string languageCode,
            ProficiencyLevel proficiencyLevel)
        {
            var difficulty = GetLevelDescription(proficiencyLevel);
            var childContext = GetChildContext();

            var prompt = $@"
Generate 40 business and professional vocabulary words in {language} at the {difficulty} level.

Include words/phrases for:
- Office and workplace
- Meetings and presentations
- Email and correspondence
- Business negotiations
- Professional relationships

Return ONLY a JSON array of vocabulary items in this exact format:
[
  {{
    ""word"": ""native word or phrase"",
    ""translation"": ""English translation"",
    ""pronunciation"": ""phonetic pronunciation"",
    ""partOfSpeech"": ""phrase/noun/verb/etc"",
    ""exampleSentence"": ""professional example in {language}"",
    ""exampleTranslation"": ""English translation of example""
  }}
]
{childContext}
";

            var response = await _aiService.SendMessageAsync(
                prompt,
                Personality.MotivationalCoach,
                FeatureType.Learning,
                new List<ConversationMessage>()
            );

            return ParseVocabularyJSON(response.Content);
        }

        // MARK: - Helper Methods

        private string GetLevelDescription(ProficiencyLevel level)
        {
            return level switch
            {
                ProficiencyLevel.Beginner => "beginner (A1)",
                ProficiencyLevel.Elementary => "elementary (A2)",
                ProficiencyLevel.Intermediate => "intermediate (B1)",
                ProficiencyLevel.UpperIntermediate => "upper intermediate (B2)",
                ProficiencyLevel.Advanced => "advanced (C1-C2)",
                _ => "beginner (A1)"
            };
        }

        private PartOfSpeech ParsePartOfSpeech(string posString)
        {
            var lower = posString.ToLower();
            if (lower.Contains("noun")) return PartOfSpeech.Noun;
            if (lower.Contains("verb")) return PartOfSpeech.Verb;
            if (lower.Contains("adjective") || lower.Contains("adj")) return PartOfSpeech.Adjective;
            if (lower.Contains("adverb") || lower.Contains("adv")) return PartOfSpeech.Adverb;
            if (lower.Contains("preposition") || lower.Contains("prep")) return PartOfSpeech.Preposition;
            if (lower.Contains("conjunction") || lower.Contains("conj")) return PartOfSpeech.Conjunction;
            if (lower.Contains("pronoun") || lower.Contains("pron")) return PartOfSpeech.Pronoun;
            if (lower.Contains("interjection") || lower.Contains("interj")) return PartOfSpeech.Interjection;
            return PartOfSpeech.Noun; // default fallback
        }

        private List<VocabularyWord> ParseVocabularyJSON(string jsonString)
        {
            // Extract JSON from response (AI might add text before/after)
            var jsonStart = jsonString.IndexOf('[');
            var jsonEnd = jsonString.LastIndexOf(']');

            if (jsonStart == -1 || jsonEnd == -1)
            {
                Console.WriteLine("⚠️ No JSON array found in response");
                return new List<VocabularyWord>();
            }

            var jsonSubstring = jsonString.Substring(jsonStart, jsonEnd - jsonStart + 1);

            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var vocabItems = JsonSerializer.Deserialize<List<VocabularyJSON>>(jsonSubstring, options);

                return vocabItems.Select(item => new VocabularyWord
                {
                    Word = item.Word,
                    Translation = item.Translation,
                    Pronunciation = item.Pronunciation,
                    PartOfSpeech = ParsePartOfSpeech(item.PartOfSpeech),
                    ExampleSentence = item.ExampleSentence ?? "",
                    ExampleTranslation = item.ExampleTranslation ?? ""
                }).ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to decode vocabulary JSON: {ex.Message}");
                Console.WriteLine($"JSON content: {jsonSubstring}");
                return new List<VocabularyWord>();
            }
        }
    }

    // MARK: - JSON Decoding Models

    private class VocabularyJSON
    {
        public string Word { get; set; }
        public string Translation { get; set; }
        public string Pronunciation { get; set; }
        public string PartOfSpeech { get; set; }
        public string ExampleSentence { get; set; }
        public string ExampleTranslation { get; set; }
    }

    // MARK: - Interface

    public interface IVocabularyGenerationService
    {
        Task<List<VocabularyWord>> GenerateEssentialVocabularyAsync(
            string language,
            string languageCode,
            ProficiencyLevel proficiencyLevel,
            int count = 50);

        Task<List<VocabularyWord>> GenerateInterestVocabularyAsync(
            string language,
            string languageCode,
            string interest,
            ProficiencyLevel proficiencyLevel,
            int count = 30);

        Task<List<VocabularyWord>> GenerateTravelVocabularyAsync(
            string language,
            string languageCode,
            ProficiencyLevel proficiencyLevel);

        Task<List<VocabularyWord>> GenerateBusinessVocabularyAsync(
            string language,
            string languageCode,
            ProficiencyLevel proficiencyLevel);
    }
}
