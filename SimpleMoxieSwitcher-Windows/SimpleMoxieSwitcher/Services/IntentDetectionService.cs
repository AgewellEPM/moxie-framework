using System;
using System.Collections.Generic;
using System.Linq;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for detecting user intent from conversation messages
    /// </summary>
    public class IntentDetectionService : IIntentDetectionService
    {
        // MARK: - Intent Keywords

        private readonly List<string> _playKeywords = new()
        {
            "play", "game", "fun", "silly", "joke", "laugh", "pretend", "imagine",
            "let's play", "wanna play", "can we play"
        };

        private readonly List<string> _learnKeywords = new()
        {
            "learn", "teach", "show me", "how to", "what is", "why", "explain",
            "help me understand", "I want to know", "can you teach", "homework",
            "study", "practice", "lesson"
        };

        private readonly List<string> _comfortKeywords = new()
        {
            "sad", "scared", "worried", "upset", "lonely", "miss", "hurt", "cry",
            "afraid", "nervous", "anxious", "feel bad", "not good", "help me feel",
            "I need", "comfort me"
        };

        private readonly List<string> _exploreKeywords = new()
        {
            "what if", "curious", "wonder", "explore", "discover", "find out",
            "show me around", "let's look", "I wonder", "tell me about"
        };

        private readonly List<string> _socializingKeywords = new()
        {
            "hi", "hello", "how are you", "what's up", "tell me about you",
            "let's talk", "chat", "friend", "buddy", "wanna hang out"
        };

        private readonly List<string> _storytellingKeywords = new()
        {
            "story", "tell me a story", "once upon", "adventure", "tale",
            "read me", "storytime", "bedtime story", "make up a story"
        };

        // MARK: - Subject Detection for Learning

        private readonly Dictionary<string, List<string>> _subjects = new()
        {
            ["math"] = new() { "math", "addition", "subtraction", "numbers", "counting", "multiply", "divide" },
            ["science"] = new() { "science", "experiment", "animals", "plants", "space", "earth", "nature" },
            ["reading"] = new() { "reading", "letters", "words", "alphabet", "spelling", "book" },
            ["art"] = new() { "art", "drawing", "painting", "colors", "creative", "craft" },
            ["social"] = new() { "feelings", "emotions", "friends", "sharing", "kindness", "manners" }
        };

        // MARK: - Intent Detection

        public (SessionIntent intent, double confidence) DetectIntent(List<ConversationMessage> messages)
        {
            // Analyze recent messages (last 5 or all if less)
            var recentMessages = messages.TakeLast(5).ToList();
            var text = string.Join(" ", recentMessages
                .Where(m => m.IsUser)
                .Select(m => m.Content.ToLower()));

            var scores = new Dictionary<string, double>
            {
                ["play"] = 0.0,
                ["learn"] = 0.0,
                ["comfort"] = 0.0,
                ["explore"] = 0.0,
                ["socializing"] = 0.0,
                ["storytelling"] = 0.0
            };

            // Score each intent
            scores["play"] = Score(text, _playKeywords);
            scores["comfort"] = Score(text, _comfortKeywords) * 1.2;  // Weight comfort higher
            scores["explore"] = Score(text, _exploreKeywords);
            scores["socializing"] = Score(text, _socializingKeywords);
            scores["storytelling"] = Score(text, _storytellingKeywords);

            // Check for learning with subject detection
            var learnScore = Score(text, _learnKeywords);
            var subject = DetectSubject(text);
            scores["learn"] = learnScore;

            // Detect questions (often learning or exploring)
            if (text.Contains("?"))
            {
                if (learnScore > 0)
                {
                    scores["learn"] += 0.3;
                }
                else
                {
                    scores["explore"] += 0.2;
                }
            }

            // Find highest score
            var sorted = scores.OrderByDescending(kv => kv.Value).ToList();
            var top = sorted.First();

            // If score is too low, return unknown
            if (top.Value < 0.3)
            {
                return (SessionIntent.Unknown, top.Value);
            }

            // Check if it's socializing by default (greetings at start)
            if (messages.Count <= 2 && scores["socializing"] > 0)
            {
                return (SessionIntent.Socializing, scores["socializing"]);
            }

            // Convert to SessionIntent enum
            var intent = top.Key switch
            {
                "play" => SessionIntent.Play,
                "learn" => subject != null ? SessionIntent.Learn : SessionIntent.Learn,
                "comfort" => SessionIntent.Comfort,
                "explore" => SessionIntent.Explore,
                "socializing" => SessionIntent.Socializing,
                "storytelling" => SessionIntent.Storytelling,
                _ => SessionIntent.Unknown
            };

            return (intent, Math.Min(top.Value, 1.0));
        }

        // MARK: - Drift Detection

        public bool DetectDrift(SessionIntent currentIntent, List<ConversationMessage> recentMessages)
        {
            var (detected, confidence) = DetectIntent(recentMessages);

            // High confidence in a different intent suggests drift
            if (detected != currentIntent && confidence > 0.6)
            {
                return true;
            }

            return false;
        }

        // MARK: - Redirection Suggestions

        public string GenerateRedirectionSuggestion(SessionIntent from, SessionIntent to)
        {
            return (from, to) switch
            {
                (SessionIntent.Socializing, SessionIntent.Learn) =>
                    "I notice you're curious about learning something new! Want to start a lesson together?",

                (SessionIntent.Play, SessionIntent.Learn) =>
                    "Sounds like you want to learn! Should we switch to learning mode?",

                (SessionIntent.Learn, SessionIntent.Play) =>
                    "Ready for a break from learning? Let's have some fun!",

                (SessionIntent.Learn, SessionIntent.Comfort) =>
                    "I can tell you might need a little break. Want to just talk for a bit?",

                (SessionIntent.Play, SessionIntent.Comfort) =>
                    "Is everything okay? I'm here if you need to talk.",

                (_, SessionIntent.Storytelling) =>
                    "Would you like me to tell you a story?",

                (SessionIntent.Socializing, SessionIntent.Explore) =>
                    "You seem really curious! Want to explore and discover some new things together?",

                _ => null
            };
        }

        // MARK: - Helper Methods

        private double Score(string text, List<string> keywords)
        {
            double score = 0.0;
            var words = text.Split(' ').ToList();

            foreach (var keyword in keywords)
            {
                var keywordWords = keyword.Split(' ').ToList();

                if (keywordWords.Count == 1)
                {
                    // Single word keyword
                    if (words.Contains(keyword))
                    {
                        score += 0.3;
                    }
                }
                else
                {
                    // Multi-word phrase
                    if (text.Contains(keyword))
                    {
                        score += 0.5;  // Higher weight for exact phrases
                    }
                }
            }

            return score;
        }

        private string DetectSubject(string text)
        {
            foreach (var (subject, keywords) in _subjects)
            {
                var subjectScore = Score(text, keywords);
                if (subjectScore > 0.3)
                {
                    return subject;
                }
            }
            return null;
        }
    }

    // MARK: - Interface

    public interface IIntentDetectionService
    {
        (SessionIntent intent, double confidence) DetectIntent(List<ConversationMessage> messages);
        bool DetectDrift(SessionIntent currentIntent, List<ConversationMessage> recentMessages);
        string GenerateRedirectionSuggestion(SessionIntent from, SessionIntent to);
    }

    // MARK: - Session Intent Enum

    public enum SessionIntent
    {
        Unknown,
        Play,
        Learn,
        Comfort,
        Explore,
        Socializing,
        Storytelling
    }
}
