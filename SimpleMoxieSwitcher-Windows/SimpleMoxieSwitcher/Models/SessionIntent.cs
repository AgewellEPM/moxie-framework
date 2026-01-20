using System;

namespace SimpleMoxieSwitcher.Models
{
    /// <summary>
    /// Session intent types for conversation tracking
    /// </summary>
    public enum SessionIntentType
    {
        Play,
        Learn,
        Comfort,
        Explore,
        Socializing,
        Storytelling,
        Unknown
    }

    /// <summary>
    /// Session intent with optional subject for learning
    /// </summary>
    public class SessionIntent : IEquatable<SessionIntent>
    {
        public SessionIntentType Type { get; set; }
        public string Subject { get; set; } // Used for Learn intent

        public SessionIntent(SessionIntentType type, string subject = null)
        {
            Type = type;
            Subject = subject;
        }

        public string DisplayName
        {
            get
            {
                switch (Type)
                {
                    case SessionIntentType.Play:
                        return "Playing";
                    case SessionIntentType.Learn:
                        return !string.IsNullOrEmpty(Subject) ? $"Learning: {Subject}" : "Learning";
                    case SessionIntentType.Comfort:
                        return "Comfort & Support";
                    case SessionIntentType.Explore:
                        return "Exploring";
                    case SessionIntentType.Socializing:
                        return "Chatting";
                    case SessionIntentType.Storytelling:
                        return "Story Time";
                    case SessionIntentType.Unknown:
                    default:
                        return "Unknown";
                }
            }
        }

        public string Icon
        {
            get
            {
                switch (Type)
                {
                    case SessionIntentType.Play:
                        return "🎮";
                    case SessionIntentType.Learn:
                        return "📚";
                    case SessionIntentType.Comfort:
                        return "💙";
                    case SessionIntentType.Explore:
                        return "🔍";
                    case SessionIntentType.Socializing:
                        return "💬";
                    case SessionIntentType.Storytelling:
                        return "📖";
                    case SessionIntentType.Unknown:
                    default:
                        return "❓";
                }
            }
        }

        public (double Red, double Green, double Blue) Color
        {
            get
            {
                switch (Type)
                {
                    case SessionIntentType.Play:
                        return (0.9, 0.5, 0.9); // Purple
                    case SessionIntentType.Learn:
                        return (0.3, 0.6, 0.9); // Blue
                    case SessionIntentType.Comfort:
                        return (0.5, 0.8, 0.9); // Light blue
                    case SessionIntentType.Explore:
                        return (0.9, 0.7, 0.3); // Orange
                    case SessionIntentType.Socializing:
                        return (0.5, 0.9, 0.5); // Green
                    case SessionIntentType.Storytelling:
                        return (0.9, 0.6, 0.4); // Warm orange
                    case SessionIntentType.Unknown:
                    default:
                        return (0.5, 0.5, 0.5); // Gray
                }
            }
        }

        public bool Equals(SessionIntent other)
        {
            if (other == null) return false;
            return Type == other.Type && Subject == other.Subject;
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as SessionIntent);
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(Type, Subject);
        }
    }

    /// <summary>
    /// Session state for tracking conversation intent
    /// </summary>
    public class SessionState
    {
        public SessionIntent CurrentIntent { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime LastIntentCheck { get; set; }
        public int MessagesSinceLastCheck { get; set; }
        public bool DriftDetected { get; set; }
        public double Confidence { get; set; } // 0-1

        public SessionState(SessionIntent intent = null)
        {
            CurrentIntent = intent ?? new SessionIntent(SessionIntentType.Unknown);
            StartTime = DateTime.Now;
            LastIntentCheck = DateTime.Now;
            MessagesSinceLastCheck = 0;
            DriftDetected = false;
            Confidence = 0.0;
        }

        public void UpdateIntent(SessionIntent newIntent, double confidence)
        {
            CurrentIntent = newIntent;
            Confidence = confidence;
            LastIntentCheck = DateTime.Now;
            MessagesSinceLastCheck = 0;
        }

        public void IncrementMessages()
        {
            MessagesSinceLastCheck++;
        }

        public TimeSpan SessionDuration => DateTime.Now - StartTime;

        public TimeSpan TimeSinceLastCheck => DateTime.Now - LastIntentCheck;

        public bool ShouldRecheckIntent
        {
            get
            {
                // Recheck if:
                // - 5+ messages since last check
                // - 3+ minutes since last check
                // - Drift was detected
                return MessagesSinceLastCheck >= 5 ||
                       TimeSinceLastCheck.TotalSeconds > 180 ||
                       DriftDetected;
            }
        }
    }
}