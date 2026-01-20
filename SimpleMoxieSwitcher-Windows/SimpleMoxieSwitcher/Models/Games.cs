using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Models;

/// <summary>
/// Base class for all game sessions
/// </summary>
public abstract class GameSession
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = string.Empty;
    public GameType GameType { get; set; }
    public DateTime StartTime { get; set; } = DateTime.Now;
    public DateTime? EndTime { get; set; }
    public int Score { get; set; }
    public string Difficulty { get; set; } = "medium";
    public Dictionary<string, object> Metadata { get; set; } = new();
}

/// <summary>
/// Enum for different game types
/// </summary>
public enum GameType
{
    Trivia,
    Spelling,
    MovieQuotes,
    VideoGames,
    Math,
    StoryBuilder,
    KnowledgeQuest
}

/// <summary>
/// Trivia game session
/// </summary>
public class TriviaGameSession : GameSession
{
    public List<TriviaQuestion> Questions { get; set; } = new();
    public List<int> UserAnswers { get; set; } = new();
    public string Topic { get; set; } = string.Empty;
    public int CorrectAnswers { get; set; }
    public int TotalQuestions { get; set; }

    public TriviaGameSession()
    {
        GameType = GameType.Trivia;
    }
}

/// <summary>
/// Spelling game session
/// </summary>
public class SpellingGameSession : GameSession
{
    public List<SpellingChallenge> Challenges { get; set; } = new();
    public List<string> UserSpellings { get; set; } = new();
    public int GradeLevel { get; set; } = 3;
    public int CorrectSpellings { get; set; }
    public int TotalWords { get; set; }

    public SpellingGameSession()
    {
        GameType = GameType.Spelling;
    }
}

/// <summary>
/// Movie quotes game session
/// </summary>
public class MovieQuotesGameSession : GameSession
{
    public List<MovieQuote> Quotes { get; set; } = new();
    public List<string> UserGuesses { get; set; } = new();
    public string Genre { get; set; } = string.Empty;
    public int CorrectGuesses { get; set; }

    public MovieQuotesGameSession()
    {
        GameType = GameType.MovieQuotes;
    }
}

/// <summary>
/// Movie quote model
/// </summary>
public class MovieQuote
{
    public string Quote { get; set; } = string.Empty;
    public string Movie { get; set; } = string.Empty;
    public int Year { get; set; }
    public string Character { get; set; } = string.Empty;
    public List<string> Options { get; set; } = new(); // Multiple choice options for movie title
    public int CorrectAnswerIndex { get; set; }
    public string Hint { get; set; } = string.Empty;
}

/// <summary>
/// Video games trivia session
/// </summary>
public class VideoGamesSession : GameSession
{
    public List<VideoGameQuestion> Questions { get; set; } = new();
    public List<int> UserAnswers { get; set; } = new();
    public string Platform { get; set; } = string.Empty; // PC, Console, Mobile
    public string Era { get; set; } = string.Empty; // Retro, Modern, All
    public int CorrectAnswers { get; set; }

    public VideoGamesSession()
    {
        GameType = GameType.VideoGames;
    }
}

/// <summary>
/// Video game question model
/// </summary>
public class VideoGameQuestion
{
    public string Question { get; set; } = string.Empty;
    public List<string> Options { get; set; } = new();
    public int CorrectAnswerIndex { get; set; }
    public string GameTitle { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty; // Characters, Story, Gameplay, History
    public string ImageUrl { get; set; } = string.Empty; // Optional game screenshot
}

/// <summary>
/// Math game session
/// </summary>
public class MathGameSession : GameSession
{
    public List<MathProblem> Problems { get; set; } = new();
    public List<double> UserAnswers { get; set; } = new();
    public string OperationType { get; set; } = string.Empty; // Addition, Subtraction, Multiplication, Division, Mixed
    public int GradeLevel { get; set; } = 3;
    public int CorrectAnswers { get; set; }

    public MathGameSession()
    {
        GameType = GameType.Math;
    }
}

/// <summary>
/// Story builder game session
/// </summary>
public class StoryBuilderSession : GameSession
{
    public StoryPrompt InitialPrompt { get; set; } = new();
    public List<string> StorySegments { get; set; } = new();
    public List<string> UserChoices { get; set; } = new();
    public string CompletedStory { get; set; } = string.Empty;
    public int WordCount { get; set; }
    public double CreativityScore { get; set; }

    public StoryBuilderSession()
    {
        GameType = GameType.StoryBuilder;
    }
}

/// <summary>
/// Game achievement model
/// </summary>
public class GameAchievement
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public int PointsValue { get; set; }
    public DateTime UnlockedAt { get; set; }
    public string GameType { get; set; } = string.Empty;
}

/// <summary>
/// Player statistics model
/// </summary>
public class PlayerStats
{
    public string PlayerId { get; set; } = string.Empty;
    public Dictionary<GameType, GameTypeStats> GameStats { get; set; } = new();
    public List<GameAchievement> Achievements { get; set; } = new();
    public int TotalPoints { get; set; }
    public int Level { get; set; } = 1;
    public int ExperiencePoints { get; set; }
    public DateTime LastPlayedAt { get; set; }
}

/// <summary>
/// Statistics for a specific game type
/// </summary>
public class GameTypeStats
{
    public int GamesPlayed { get; set; }
    public int TotalScore { get; set; }
    public int HighScore { get; set; }
    public double AverageScore { get; set; }
    public TimeSpan TotalPlayTime { get; set; }
    public double WinRate { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
}

/// <summary>
/// Game leaderboard entry
/// </summary>
public class LeaderboardEntry
{
    public string PlayerId { get; set; } = string.Empty;
    public string PlayerName { get; set; } = string.Empty;
    public int Score { get; set; }
    public GameType GameType { get; set; }
    public string Difficulty { get; set; } = string.Empty;
    public DateTime AchievedAt { get; set; }
    public int Rank { get; set; }
}

/// <summary>
/// Game reward model
/// </summary>
public class GameReward
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public RewardType Type { get; set; }
    public int Value { get; set; }
    public string IconUrl { get; set; } = string.Empty;
}

/// <summary>
/// Reward types
/// </summary>
public enum RewardType
{
    Points,
    Badge,
    Unlock,
    Cosmetic,
    PowerUp
}