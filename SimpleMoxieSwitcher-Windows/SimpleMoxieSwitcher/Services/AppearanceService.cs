using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for managing Moxie's appearance customization
    /// </summary>
    public class AppearanceService : IAppearanceService
    {
        private readonly IMQTTService _mqttService;
        private readonly HttpClient _httpClient;
        private AppearanceSettings _currentAppearance;

        public AppearanceService(IMQTTService mqttService)
        {
            _mqttService = mqttService;
            _httpClient = new HttpClient();
        }

        public async Task ApplyAppearanceAsync(AppearanceSettings settings)
        {
            try
            {
                await SubmitFaceCustomizationAsync(
                    settings.Eyes,
                    settings.FaceColors,
                    settings.EyeDesigns,
                    settings.FaceDesigns,
                    settings.EyelidDesigns,
                    settings.Mouth,
                    settings.HeadHair,
                    settings.FacialHair,
                    settings.Brows,
                    settings.Glasses,
                    settings.Nose
                );
                _currentAppearance = settings;
                Console.WriteLine("✅ Appearance applied successfully");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error applying appearance: {ex.Message}");
                throw;
            }
        }

        public AppearanceSettings GetCurrentAppearance()
        {
            return _currentAppearance;
        }

        private async Task SubmitFaceCustomizationAsync(
            string eyes,
            string faceColors,
            string eyeDesigns,
            string faceDesigns,
            string eyelidDesigns,
            string mouth,
            string headHair,
            string facialHair,
            string brows,
            string glasses,
            string nose)
        {
            // Build form data
            var formData = new Dictionary<string, string>();

            void AddAsset(string value, string key, string prefix)
            {
                if (value == "Default")
                {
                    formData[key] = "--";
                }
                else
                {
                    formData[key] = prefix + value;
                }
            }

            AddAsset(eyes, "asset_Eyes", "MX_010_Eyes_");
            AddAsset(faceColors, "asset_Face_Colors", "MX_020_Face_Colors_");
            AddAsset(eyeDesigns, "asset_Eye_Designs", "MX_030_Eye_Designs_");
            AddAsset(faceDesigns, "asset_Face_Designs", "MX_040_Face_Designs_");
            AddAsset(eyelidDesigns, "asset_Eyelid_Designs", "MX_050_Eyelid_Designs_");
            AddAsset(mouth, "asset_Mouth", "MX_060_Mouth_");
            AddAsset(headHair, "asset_Head_Hair", "MX_080_Head_Hair_");
            AddAsset(facialHair, "asset_Facial_Hair", "MX_090_Facial_Hair_");
            AddAsset(brows, "asset_Brows", "MX_100_Brows_");
            AddAsset(glasses, "asset_Glasses", "MX_120_Glasses_");
            AddAsset(nose, "asset_Nose", "MX_130_Nose_");

            // Get CSRF token first
            var csrfToken = await GetCSRFTokenAsync();

            // Create URL-encoded form body
            var bodyComponents = new List<string>
            {
                $"csrfmiddlewaretoken={Uri.EscapeDataString(csrfToken)}"
            };

            foreach (var kvp in formData)
            {
                bodyComponents.Add($"{kvp.Key}={Uri.EscapeDataString(kvp.Value)}");
            }

            var bodyString = string.Join("&", bodyComponents);

            // Make HTTP POST request to OpenMoxie
            var content = new StringContent(bodyString, Encoding.UTF8, "application/x-www-form-urlencoded");
            var response = await _httpClient.PostAsync("http://localhost:8003/hive/face_edit/1", content);

            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"HTTP request failed with status code: {response.StatusCode}");
            }

            Console.WriteLine("🎨 Face customization submitted successfully");
        }

        private async Task<string> GetCSRFTokenAsync()
        {
            // Fetch the face customization page to get CSRF token
            var response = await _httpClient.GetAsync("http://localhost:8003/hive/face/1");
            var html = await response.Content.ReadAsStringAsync();

            // Extract CSRF token from HTML using regex
            var match = Regex.Match(html, @"name=""csrfmiddlewaretoken""\s+value=""([^""]+)""");
            if (match.Success)
            {
                return match.Groups[1].Value;
            }

            throw new Exception("CSRF token not found in HTML");
        }
    }

    // MARK: - Interface

    public interface IAppearanceService
    {
        Task ApplyAppearanceAsync(AppearanceSettings settings);
        AppearanceSettings GetCurrentAppearance();
    }
}
