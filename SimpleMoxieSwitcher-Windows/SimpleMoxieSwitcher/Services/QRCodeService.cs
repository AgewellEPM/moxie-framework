using System;
using System.Drawing;
using System.IO;
using System.Text.Json;
using QRCoder;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for generating QR codes for sharing configurations
    /// </summary>
    public class QRCodeService : IQRCodeService
    {
        public Bitmap GenerateQRCode(string data, int pixelsPerModule = 20)
        {
            using (var qrGenerator = new QRCodeGenerator())
            {
                var qrCodeData = qrGenerator.CreateQrCode(data, QRCodeGenerator.ECCLevel.Q);
                using (var qrCode = new QRCode(qrCodeData))
                {
                    return qrCode.GetGraphic(pixelsPerModule);
                }
            }
        }

        public byte[] GenerateQRCodeBytes(string data, int pixelsPerModule = 20)
        {
            var bitmap = GenerateQRCode(data, pixelsPerModule);
            using (var stream = new MemoryStream())
            {
                bitmap.Save(stream, System.Drawing.Imaging.ImageFormat.Png);
                return stream.ToArray();
            }
        }

        public string GenerateQRCodeBase64(string data, int pixelsPerModule = 20)
        {
            var bytes = GenerateQRCodeBytes(data, pixelsPerModule);
            return Convert.ToBase64String(bytes);
        }

        // MARK: - Specialized QR Code Generators

        public Bitmap GeneratePersonalityQRCode(Models.Personality personality, int pixelsPerModule = 20)
        {
            var data = new
            {
                type = "personality",
                name = personality.Name,
                prompt = personality.Prompt,
                opener = personality.Opener,
                temperature = personality.Temperature,
                maxTokens = personality.MaxTokens,
                emoji = personality.Emoji
            };

            var json = JsonSerializer.Serialize(data);
            return GenerateQRCode(json, pixelsPerModule);
        }

        public Bitmap GenerateChildProfileQRCode(Models.ChildProfile profile, int pixelsPerModule = 20)
        {
            var data = new
            {
                type = "child_profile",
                name = profile.Name,
                age = profile.Age,
                interests = profile.Interests,
                favoriteColor = profile.FavoriteColor,
                gradeLevel = profile.GradeLevel
            };

            var json = JsonSerializer.Serialize(data);
            return GenerateQRCode(json, pixelsPerModule);
        }

        public Bitmap GenerateSettingsQRCode(
            string mqttHost,
            int mqttPort,
            string openaiKey,
            string anthropicKey,
            int pixelsPerModule = 20)
        {
            var data = new
            {
                type = "settings",
                mqttHost,
                mqttPort,
                openaiKey = string.IsNullOrEmpty(openaiKey) ? "" : "***", // Don't expose full keys
                anthropicKey = string.IsNullOrEmpty(anthropicKey) ? "" : "***",
                hasOpenAI = !string.IsNullOrEmpty(openaiKey),
                hasAnthropic = !string.IsNullOrEmpty(anthropicKey)
            };

            var json = JsonSerializer.Serialize(data);
            return GenerateQRCode(json, pixelsPerModule);
        }

        public Bitmap GenerateWiFiQRCode(string ssid, string password, string encryption = "WPA", int pixelsPerModule = 20)
        {
            // WiFi QR code format: WIFI:T:WPA;S:ssid;P:password;;
            var data = $"WIFI:T:{encryption};S:{ssid};P:{password};;";
            return GenerateQRCode(data, pixelsPerModule);
        }

        public Bitmap GenerateURLQRCode(string url, int pixelsPerModule = 20)
        {
            return GenerateQRCode(url, pixelsPerModule);
        }

        // MARK: - Save to File

        public void SaveQRCodeToFile(Bitmap qrCode, string filePath)
        {
            qrCode.Save(filePath, System.Drawing.Imaging.ImageFormat.Png);
            Console.WriteLine($"✅ QR code saved to: {filePath}");
        }

        public void SaveQRCodeToFile(string data, string filePath, int pixelsPerModule = 20)
        {
            var qrCode = GenerateQRCode(data, pixelsPerModule);
            SaveQRCodeToFile(qrCode, filePath);
        }
    }

    // MARK: - Interface

    public interface IQRCodeService
    {
        Bitmap GenerateQRCode(string data, int pixelsPerModule = 20);
        byte[] GenerateQRCodeBytes(string data, int pixelsPerModule = 20);
        string GenerateQRCodeBase64(string data, int pixelsPerModule = 20);

        Bitmap GeneratePersonalityQRCode(Models.Personality personality, int pixelsPerModule = 20);
        Bitmap GenerateChildProfileQRCode(Models.ChildProfile profile, int pixelsPerModule = 20);
        Bitmap GenerateSettingsQRCode(string mqttHost, int mqttPort, string openaiKey, string anthropicKey, int pixelsPerModule = 20);
        Bitmap GenerateWiFiQRCode(string ssid, string password, string encryption = "WPA", int pixelsPerModule = 20);
        Bitmap GenerateURLQRCode(string url, int pixelsPerModule = 20);

        void SaveQRCodeToFile(Bitmap qrCode, string filePath);
        void SaveQRCodeToFile(string data, string filePath, int pixelsPerModule = 20);
    }
}
