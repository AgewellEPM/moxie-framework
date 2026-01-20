using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for generating game content using AI
    /// </summary>
    public class GameContentGenerationService : IGameContentGenerationService
    {
        private readonly IAIService _aiService;
        private readonly IChildProfileService _childProfileService;

        public GameContentGenerationService(IAIService aiService, IChildProfileService childProfileService)
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
            context += "The child you're creating content for:\n";
            context += $"- Name: {profile.Name}\n";

            if (profile.Age.HasValue)
            {
                context += $"- Age: {profile.Age} years old\n";
            }

            if (profile.Interests != null && profile.Interests.Any())
            {
                context += $"- Interests: {string.Join(", ", profile.Interests)}\n";
            }

            context += "\nPlease tailor the difficulty, examples, and topics to be appropriate and engaging for this child.\n";

            return context;
        }

        // MARK: - Trivia Generation

        /// <summary>
        /// Generate age-appropriate trivia questions
        /// </summary>
        public async Task<List<TriviaQuestion>> GenerateTriviaQuestionsAsync(
            string category,
            Difficulty difficulty,
            int count = 10)
        {
            var categoryPrompt = category != null ? $"about {category}" : "on various topics";
            var childContext = GetChildContext();

            var prompt = $@"
Generate {count} fun, age-appropriate trivia questions {categoryPrompt} for a {difficulty} difficulty level.

Return ONLY a JSON array in this exact format:
[
  {{
    ""category"": ""Science/History/Geography/etc"",
    ""question"": ""The question text"",
    ""options"": [""option1"", ""option2"", ""option3"", ""option4""],
    ""correctAnswer"": 0
  }}
]

Make sure questions are engaging, educational, and appropriate for children.
The correctAnswer is the index (0-3) of the correct option in the options array.
Vary the categories across questions.
{childContext}
";

            var response = await _aiService.SendMessageAsync(
                prompt,
                Personality.MotivationalCoach,
                FeatureType.Learning,
                new List<ConversationMessage>()
            );

            return ParseTriviaJSON(response.Content, difficulty);
        }

        // MARK: - Spelling Generation

        /// <summary>
        /// Generate spelling words appropriate for age/grade level
        /// </summary>
        public async Task<List<SpellingWord>> GenerateSpellingWordsAsync(
            string gradeLevel,
            string category,
            Difficulty difficulty,
            int count = 10)
        {
            var categoryPrompt = category != null ? $"related to {category}" : "common words";
            var childContext = GetChildContext();

            var prompt = $@"
Generate {count} spelling words {categoryPrompt} appropriate for {gradeLevel} grade level at {difficulty} difficulty.

Return ONLY a JSON array in this exact format:
[
  {{
    ""word"": ""the word to spell"",
    ""definition"": ""simple definition"",
    ""audioHint"": ""phonetic pronunciation (e.g., frend, byoo-tuh-fuhl)""
  }}
]

Words should be age-appropriate and educational.
{childContext}
";

            var response = await _aiService.SendMessageAsync(
                prompt,
                Personality.MotivationalCoach,
                FeatureType.Learning,
                new List<ConversationMessage>()
            );

            return ParseSpellingJSON(response.Content, difficulty);
        }

        // MARK: - Movie Quote Generation

        /// <summary>
        /// Generate family-friendly movie quotes
        /// </summary>
        public async Task<List<MovieLineChallenge>> GenerateMovieQuotesAsync(
            string genre,
            Difficulty difficulty,
            int count = 8)
        {
            var genrePrompt = genre != null ? $"from {genre} movies" : "from family-friendly movies";
            var childContext = GetChildContext();

            var prompt = $@"
Generate {count} famous movie quotes {genrePrompt} at {difficulty} difficulty.

Return ONLY a JSON array in this exact format:
[
  {{
    ""movieLine"": ""The movie quote"",
    ""correctMovie"": ""Correct Movie title"",
    ""options"": [""Movie1"", ""Movie2"", ""Movie3"", ""Movie4""],
    ""year"": ""Release year""
  }}
]

Only include quotes from G, PG, or PG-13 rated family-friendly movies.
Quotes should be memorable and recognizable.
The options array should include the correct movie and 3 plausible wrong answers.
{childContext}
";

            var response = await _aiService.SendMessageAsync(
                prompt,
                Personality.MotivationalCoach,
                FeatureType.Learning,
                new List<ConversationMessage>()
            );

            return ParseMovieQuoteJSON(response.Content, difficulty);
        }

        // MARK: - Video Game Challenge Generation

        /// <summary>
        /// Generate video game trivia/challenges
        /// </summary>
        public async Task<List<VideoGameChallenge>> GenerateVideoGameChallengesAsync(
            string category,
            Difficulty difficulty,
            int count = 8)
        {
            var categoryPrompt = category != null ? $"about {category}" : "about popular video games";
            var childContext = GetChildContext();

            var prompt = $@"
Generate {count} video game trivia questions or challenges {categoryPrompt} at {difficulty} difficulty.

Return ONLY a JSON array in this exact format:
[
  {{
    ""clue"": ""The clue or description"",
    ""correctGame"": ""Correct game title"",
    ""options"": [""Game1"", ""Game2"", ""Game3"", ""Game4""],
    ""franchise"": ""Game franchise (optional, can be null)""
  }}
]

Focus on family-friendly games (E or E10+ rated).
The options array should include the correct game and 3 plausible wrong answers.
Clues can be about game mechanics, characters, history, or fun facts.
{childContext}
";

            var response = await _aiService.SendMessageAsync(
                prompt,
                Personality.MotivationalCoach,
                FeatureType.Learning,
                new List<ConversationMessage>()
            );

            return ParseVideoGameChallengeJSON(response.Content, difficulty);
        }

        // MARK: - JSON Parsing

        private List<TriviaQuestion> ParseTriviaJSON(string jsonString, Difficulty difficulty)
        {
            var jsonStart = jsonString.IndexOf('[');
            var jsonEnd = jsonString.LastIndexOf(']');

            if (jsonStart == -1 || jsonEnd == -1)
            {
                Console.WriteLine("⚠️ No JSON array found in trivia response");
                return new List<TriviaQuestion>();
            }

            var jsonSubstring = jsonString.Substring(jsonStart, jsonEnd - jsonStart + 1);

            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var items = JsonSerializer.Deserialize<List<TriviaJSON>>(jsonSubstring, options);
                return items.Select(item => new TriviaQuestion
                {
                    Category = item.Category,
                    Question = item.Question,
                    Options = item.Options,
                    CorrectAnswer = item.CorrectAnswer,
                    Difficulty = difficulty
                }).ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to decode trivia JSON: {ex.Message}");
                return new List<TriviaQuestion>();
            }
        }

        private List<SpellingWord> ParseSpellingJSON(string jsonString, Difficulty difficulty)
        {
            var jsonStart = jsonString.IndexOf('[');
            var jsonEnd = jsonString.LastIndexOf(']');

            if (jsonStart == -1 || jsonEnd == -1)
            {
                Console.WriteLine("⚠️ No JSON array found in spelling response");
                return new List<SpellingWord>();
            }

            var jsonSubstring = jsonString.Substring(jsonStart, jsonEnd - jsonStart + 1);

            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var items = JsonSerializer.Deserialize<List<SpellingJSON>>(jsonSubstring, options);
                return items.Select(item => new SpellingWord
                {
                    Word = item.Word,
                    Definition = item.Definition,
                    Difficulty = difficulty,
                    AudioHint = item.AudioHint
                }).ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to decode spelling JSON: {ex.Message}");
                return new List<SpellingWord>();
            }
        }

        private List<MovieLineChallenge> ParseMovieQuoteJSON(string jsonString, Difficulty difficulty)
        {
            var jsonStart = jsonString.IndexOf('[');
            var jsonEnd = jsonString.LastIndexOf(']');

            if (jsonStart == -1 || jsonEnd == -1)
            {
                Console.WriteLine("⚠️ No JSON array found in movie quote response");
                return new List<MovieLineChallenge>();
            }

            var jsonSubstring = jsonString.Substring(jsonStart, jsonEnd - jsonStart + 1);

            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var items = JsonSerializer.Deserialize<List<MovieQuoteJSON>>(jsonSubstring, options);
                return items.Select(item => new MovieLineChallenge
                {
                    MovieLine = item.MovieLine,
                    CorrectMovie = item.CorrectMovie,
                    Options = item.Options,
                    Year = item.Year,
                    Difficulty = difficulty
                }).ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to decode movie quote JSON: {ex.Message}");
                return new List<MovieLineChallenge>();
            }
        }

        private List<VideoGameChallenge> ParseVideoGameChallengeJSON(string jsonString, Difficulty difficulty)
        {
            var jsonStart = jsonString.IndexOf('[');
            var jsonEnd = jsonString.LastIndexOf(']');

            if (jsonStart == -1 || jsonEnd == -1)
            {
                Console.WriteLine("⚠️ No JSON array found in video game challenge response");
                return new List<VideoGameChallenge>();
            }

            var jsonSubstring = jsonString.Substring(jsonStart, jsonEnd - jsonStart + 1);

            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var items = JsonSerializer.Deserialize<List<VideoGameChallengeJSON>>(jsonSubstring, options);
                return items.Select(item => new VideoGameChallenge
                {
                    Clue = item.Clue,
                    CorrectGame = item.CorrectGame,
                    Options = item.Options,
                    Franchise = item.Franchise,
                    Difficulty = difficulty
                }).ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to decode video game challenge JSON: {ex.Message}");
                return new List<VideoGameChallenge>();
            }
        }
    }

    // MARK: - JSON Decoding Models

    private class TriviaJSON
    {
        public string Category { get; set; }
        public string Question { get; set; }
        public List<string> Options { get; set; }
        public int CorrectAnswer { get; set; }
    }

    private class SpellingJSON
    {
        public string Word { get; set; }
        public string Definition { get; set; }
        public string AudioHint { get; set; }
    }

    private class MovieQuoteJSON
    {
        public string MovieLine { get; set; }
        public string CorrectMovie { get; set; }
        public List<string> Options { get; set; }
        public string Year { get; set; }
    }

    private class VideoGameChallengeJSON
    {
        public string Clue { get; set; }
        public string CorrectGame { get; set; }
        public List<string> Options { get; set; }
        public string Franchise { get; set; }
    }

    // MARK: - Interface

    public interface IGameContentGenerationService
    {
        Task<List<TriviaQuestion>> GenerateTriviaQuestionsAsync(
            string category,
            Difficulty difficulty,
            int count = 10);

        Task<List<SpellingWord>> GenerateSpellingWordsAsync(
            string gradeLevel,
            string category,
            Difficulty difficulty,
            int count = 10);

        Task<List<MovieLineChallenge>> GenerateMovieQuotesAsync(
            string genre,
            Difficulty difficulty,
            int count = 8);

        Task<List<VideoGameChallenge>> GenerateVideoGameChallengesAsync(
            string category,
            Difficulty difficulty,
            int count = 8);
    }
}
