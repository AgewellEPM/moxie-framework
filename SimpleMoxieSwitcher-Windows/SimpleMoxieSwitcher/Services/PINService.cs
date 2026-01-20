using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for managing parent PIN protection
    /// </summary>
    public class PINService : IPINService
    {
        private readonly string _pinPath;
        private readonly string _salt = "MoxieSwitcherPINSalt2024"; // Static salt for consistency

        public PINService()
        {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var appFolder = Path.Combine(appData, "SimpleMoxieSwitcher");
            Directory.CreateDirectory(appFolder);
            _pinPath = Path.Combine(appFolder, "parent_pin.dat");
        }

        // MARK: - PIN Creation

        /// <summary>
        /// Create a new parent PIN
        /// </summary>
        public void CreatePIN(string pin)
        {
            // Validate PIN format
            if (pin.Length != 6)
            {
                throw new PINException("PIN must be exactly 6 digits.");
            }

            if (!pin.All(char.IsDigit))
            {
                throw new PINException("PIN must contain only digits.");
            }

            // Check PIN strength
            var strength = ValidatePINStrength(pin);
            if (strength == PINStrength.TooWeak)
            {
                throw new PINException("PIN is too weak. Avoid sequences (123456) or repeating digits (111111).");
            }

            // Hash and store PIN
            var hashedPIN = HashPIN(pin);
            File.WriteAllText(_pinPath, hashedPIN);

            Console.WriteLine("🔐 Parent PIN created successfully");
        }

        // MARK: - PIN Validation

        /// <summary>
        /// Validate a PIN against the stored hash
        /// </summary>
        public bool ValidatePIN(string pin)
        {
            if (pin.Length != 6)
            {
                throw new PINException("PIN must be exactly 6 digits.");
            }

            var storedHash = RetrievePINHash();
            var inputHash = HashPIN(pin);
            var isValid = storedHash == inputHash;

            // Record attempt in ModeContext (if you have this implemented)
            // ModeContext.Instance.RecordPINAttempt(isValid);

            Console.WriteLine($"🔐 PIN validation: {(isValid ? "Success" : "Failed")}");

            return isValid;
        }

        // MARK: - PIN Deletion

        /// <summary>
        /// Delete the stored PIN
        /// </summary>
        public void DeletePIN()
        {
            if (File.Exists(_pinPath))
            {
                File.Delete(_pinPath);
                Console.WriteLine("🔐 Parent PIN deleted");
            }
        }

        // MARK: - PIN Existence Check

        /// <summary>
        /// Check if a PIN is currently set
        /// </summary>
        public bool HasPIN()
        {
            return File.Exists(_pinPath) && new FileInfo(_pinPath).Length > 0;
        }

        // MARK: - PIN Strength Validation

        /// <summary>
        /// Validate the strength of a PIN
        /// </summary>
        public PINStrength ValidatePINStrength(string pin)
        {
            if (pin.Length != 6)
            {
                return PINStrength.Invalid;
            }

            if (!pin.All(char.IsDigit))
            {
                return PINStrength.Invalid;
            }

            // Check for weak patterns
            if (IsSequential(pin))
            {
                return PINStrength.TooWeak;
            }

            if (IsRepeating(pin))
            {
                return PINStrength.TooWeak;
            }

            if (IsCommonPIN(pin))
            {
                return PINStrength.Weak;
            }

            // If it passes all checks, it's strong
            return PINStrength.Strong;
        }

        // MARK: - Private Helpers

        private string HashPIN(string pin)
        {
            using (var sha256 = SHA256.Create())
            {
                var saltedPIN = pin + _salt;
                var bytes = Encoding.UTF8.GetBytes(saltedPIN);
                var hash = sha256.ComputeHash(bytes);
                return Convert.ToBase64String(hash);
            }
        }

        private string RetrievePINHash()
        {
            if (!File.Exists(_pinPath))
            {
                throw new PINException("No PIN is set. Please create a PIN first.");
            }

            return File.ReadAllText(_pinPath);
        }

        private bool IsSequential(string pin)
        {
            var digits = pin.Select(c => int.Parse(c.ToString())).ToArray();

            // Check ascending sequence (123456, 234567, etc.)
            bool isAscending = true;
            for (int i = 0; i < 5; i++)
            {
                if (digits[i + 1] != digits[i] + 1)
                {
                    isAscending = false;
                    break;
                }
            }

            // Check descending sequence (654321, 543210, etc.)
            bool isDescending = true;
            for (int i = 0; i < 5; i++)
            {
                if (digits[i + 1] != digits[i] - 1)
                {
                    isDescending = false;
                    break;
                }
            }

            return isAscending || isDescending;
        }

        private bool IsRepeating(string pin)
        {
            var firstChar = pin[0];
            return pin.All(c => c == firstChar);
        }

        private bool IsCommonPIN(string pin)
        {
            var commonPINs = new[]
            {
                "123456", "654321", "111111", "000000",
                "121212", "112233", "123123", "696969",
                "101010", "123321", "131313"
            };
            return commonPINs.Contains(pin);
        }
    }

    // MARK: - PIN Service Interface

    public interface IPINService
    {
        void CreatePIN(string pin);
        bool ValidatePIN(string pin);
        void DeletePIN();
        bool HasPIN();
        PINStrength ValidatePINStrength(string pin);
    }

    // MARK: - PIN Exception

    public class PINException : Exception
    {
        public PINException(string message) : base(message) { }
    }

    // MARK: - PIN Strength

    public enum PINStrength
    {
        Invalid,
        TooWeak,
        Weak,
        Strong
    }

    public static class PINStrengthExtensions
    {
        public static string DisplayName(this PINStrength strength)
        {
            return strength switch
            {
                PINStrength.Invalid => "Invalid",
                PINStrength.TooWeak => "Too Weak",
                PINStrength.Weak => "Weak",
                PINStrength.Strong => "Strong",
                _ => "Unknown"
            };
        }

        public static string Color(this PINStrength strength)
        {
            return strength switch
            {
                PINStrength.Invalid => "#FF0000",     // Red
                PINStrength.TooWeak => "#FF6B00",     // Orange
                PINStrength.Weak => "#FFD700",        // Yellow
                PINStrength.Strong => "#00FF00",      // Green
                _ => "#CCCCCC"
            };
        }

        public static double Progress(this PINStrength strength)
        {
            return strength switch
            {
                PINStrength.Invalid => 0.0,
                PINStrength.TooWeak => 0.33,
                PINStrength.Weak => 0.66,
                PINStrength.Strong => 1.0,
                _ => 0.0
            };
        }
    }
}
