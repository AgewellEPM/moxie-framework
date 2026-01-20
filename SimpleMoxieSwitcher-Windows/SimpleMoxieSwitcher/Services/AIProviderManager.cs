using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Windows.Storage;

namespace SimpleMoxieSwitcher.Services;

/// <summary>
/// Manages AI provider configurations and credentials
/// </summary>
public class AIProviderManager
{
    private readonly string _configFilePath;
    private List<AIProviderConfig> _providers = new();
    private AIProviderConfig? _activeProvider;

    public AIProviderManager()
    {
        var localFolder = ApplicationData.Current.LocalFolder.Path;
        _configFilePath = Path.Combine(localFolder, "ai_providers.json");
        LoadConfigurations();
    }

    /// <summary>
    /// Get all configured providers
    /// </summary>
    public List<AIProviderConfig> GetProviders() => new(_providers);

    /// <summary>
    /// Get the currently active provider
    /// </summary>
    public AIProviderConfig? GetActiveProvider() => _activeProvider;

    /// <summary>
    /// Add or update a provider configuration
    /// </summary>
    public void UpdateProvider(AIProviderConfig config)
    {
        var existing = _providers.FirstOrDefault(p => p.Provider == config.Provider);
        if (existing != null)
        {
            _providers.Remove(existing);
        }

        _providers.Add(config);

        if (config.IsActive)
        {
            // Deactivate other providers
            foreach (var provider in _providers.Where(p => p.Provider != config.Provider))
            {
                provider.IsActive = false;
            }
            _activeProvider = config;
        }

        SaveConfigurations();
    }

    /// <summary>
    /// Set the active provider
    /// </summary>
    public void SetActiveProvider(AIProvider provider)
    {
        foreach (var p in _providers)
        {
            p.IsActive = p.Provider == provider;
        }

        _activeProvider = _providers.FirstOrDefault(p => p.Provider == provider);
        SaveConfigurations();
    }

    /// <summary>
    /// Remove a provider configuration
    /// </summary>
    public void RemoveProvider(AIProvider provider)
    {
        _providers.RemoveAll(p => p.Provider == provider);
        if (_activeProvider?.Provider == provider)
        {
            _activeProvider = _providers.FirstOrDefault();
            if (_activeProvider != null)
            {
                _activeProvider.IsActive = true;
            }
        }
        SaveConfigurations();
    }

    /// <summary>
    /// Test a provider's API key
    /// </summary>
    public async Task<bool> TestProviderAsync(AIProvider provider, string apiKey)
    {
        // This would be implemented with actual API calls
        // For now, just check if the key is not empty
        return !string.IsNullOrWhiteSpace(apiKey);
    }

    /// <summary>
    /// Get provider display information
    /// </summary>
    public static AIProviderInfo GetProviderInfo(AIProvider provider)
    {
        return provider switch
        {
            AIProvider.OpenAI => new AIProviderInfo
            {
                Provider = AIProvider.OpenAI,
                Name = "OpenAI",
                Description = "ChatGPT and GPT-4 models",
                Icon = "🤖",
                WebsiteUrl = "https://platform.openai.com",
                ApiKeyUrl = "https://platform.openai.com/api-keys",
                PricingInfo = "GPT-3.5: $0.002/1K tokens | GPT-4: $0.03/1K tokens",
                Recommended = true
            },
            AIProvider.Anthropic => new AIProviderInfo
            {
                Provider = AIProvider.Anthropic,
                Name = "Anthropic",
                Description = "Claude 3 family of models",
                Icon = "🧠",
                WebsiteUrl = "https://www.anthropic.com",
                ApiKeyUrl = "https://console.anthropic.com/account/keys",
                PricingInfo = "Claude 3 Haiku: $0.00025/1K tokens | Claude 3 Opus: $0.015/1K tokens",
                Recommended = false
            },
            AIProvider.DeepSeek => new AIProviderInfo
            {
                Provider = AIProvider.DeepSeek,
                Name = "DeepSeek",
                Description = "Cost-effective AI models",
                Icon = "🌊",
                WebsiteUrl = "https://www.deepseek.com",
                ApiKeyUrl = "https://platform.deepseek.com/api-keys",
                PricingInfo = "Very competitive pricing",
                Recommended = false
            },
            AIProvider.Gemini => new AIProviderInfo
            {
                Provider = AIProvider.Gemini,
                Name = "Google Gemini",
                Description = "Google's latest AI models",
                Icon = "✨",
                WebsiteUrl = "https://ai.google.dev",
                ApiKeyUrl = "https://aistudio.google.com/apikey",
                PricingInfo = "FREE TIER: 15 requests/min | Pro: Pay as you go",
                Recommended = true,
                IsFree = true
            },
            AIProvider.Ollama => new AIProviderInfo
            {
                Provider = AIProvider.Ollama,
                Name = "Ollama (Local)",
                Description = "Run AI models locally on your computer - completely free and private",
                Icon = "🦙",
                WebsiteUrl = "https://ollama.ai",
                ApiKeyUrl = "",  // No API key needed
                PricingInfo = "100% FREE - Runs on your computer",
                Recommended = true,
                IsFree = true,
                NoApiKeyRequired = true
            },
            AIProvider.GroqCloud => new AIProviderInfo
            {
                Provider = AIProvider.GroqCloud,
                Name = "Groq Cloud",
                Description = "Ultra-fast inference with generous free tier",
                Icon = "⚡",
                WebsiteUrl = "https://groq.com",
                ApiKeyUrl = "https://console.groq.com/keys",
                PricingInfo = "FREE: 14,400 requests/day | Blazing fast",
                Recommended = true,
                IsFree = true
            },
            _ => throw new ArgumentException($"Unknown provider: {provider}")
        };
    }

    /// <summary>
    /// Load configurations from disk
    /// </summary>
    private void LoadConfigurations()
    {
        try
        {
            if (File.Exists(_configFilePath))
            {
                var json = File.ReadAllText(_configFilePath);
                var configs = JsonSerializer.Deserialize<List<AIProviderConfig>>(json);
                if (configs != null)
                {
                    _providers = configs;
                    _activeProvider = _providers.FirstOrDefault(p => p.IsActive);
                }
            }
            else
            {
                // Create default configuration with OpenAI
                var defaultConfig = new AIProviderConfig
                {
                    Provider = AIProvider.OpenAI,
                    ApiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY") ?? string.Empty,
                    SelectedModel = "gpt-3.5-turbo",
                    IsActive = true
                };

                if (!string.IsNullOrEmpty(defaultConfig.ApiKey))
                {
                    _providers.Add(defaultConfig);
                    _activeProvider = defaultConfig;
                    SaveConfigurations();
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error loading AI provider configurations: {ex.Message}");
        }
    }

    /// <summary>
    /// Save configurations to disk
    /// </summary>
    private void SaveConfigurations()
    {
        try
        {
            var json = JsonSerializer.Serialize(_providers, new JsonSerializerOptions
            {
                WriteIndented = true
            });
            File.WriteAllText(_configFilePath, json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error saving AI provider configurations: {ex.Message}");
        }
    }

    /// <summary>
    /// Get usage statistics for a provider
    /// </summary>
    public AIProviderUsageStats GetUsageStats(AIProvider provider)
    {
        // This would be implemented with actual usage tracking
        return new AIProviderUsageStats
        {
            Provider = provider,
            TotalRequests = 0,
            TotalTokens = 0,
            EstimatedCost = 0.0,
            LastUsed = DateTime.Now,
            ThisMonthRequests = 0,
            ThisMonthTokens = 0,
            ThisMonthCost = 0.0
        };
    }

    /// <summary>
    /// Import provider configuration from JSON
    /// </summary>
    public bool ImportConfiguration(string jsonConfig)
    {
        try
        {
            var config = JsonSerializer.Deserialize<AIProviderConfig>(jsonConfig);
            if (config != null)
            {
                UpdateProvider(config);
                return true;
            }
        }
        catch
        {
            // Invalid JSON
        }
        return false;
    }

    /// <summary>
    /// Export provider configuration as JSON
    /// </summary>
    public string ExportConfiguration(AIProvider provider)
    {
        var config = _providers.FirstOrDefault(p => p.Provider == provider);
        if (config != null)
        {
            // Remove sensitive data for export
            var exportConfig = new AIProviderConfig
            {
                Provider = config.Provider,
                SelectedModel = config.SelectedModel,
                Settings = config.Settings,
                IsActive = config.IsActive
                // ApiKey is intentionally excluded
            };

            return JsonSerializer.Serialize(exportConfig, new JsonSerializerOptions
            {
                WriteIndented = true
            });
        }
        return string.Empty;
    }
}

/// <summary>
/// AI provider information
/// </summary>
public class AIProviderInfo
{
    public AIProvider Provider { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public string WebsiteUrl { get; set; } = string.Empty;
    public string ApiKeyUrl { get; set; } = string.Empty;
    public string PricingInfo { get; set; } = string.Empty;
    public bool Recommended { get; set; }
    public bool IsFree { get; set; }
    public bool NoApiKeyRequired { get; set; }
}

/// <summary>
/// AI provider usage statistics
/// </summary>
public class AIProviderUsageStats
{
    public AIProvider Provider { get; set; }
    public int TotalRequests { get; set; }
    public int TotalTokens { get; set; }
    public double EstimatedCost { get; set; }
    public DateTime LastUsed { get; set; }
    public int ThisMonthRequests { get; set; }
    public int ThisMonthTokens { get; set; }
    public double ThisMonthCost { get; set; }
}