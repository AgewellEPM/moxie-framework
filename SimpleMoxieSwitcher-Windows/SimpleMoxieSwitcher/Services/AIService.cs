using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services;

/// <summary>
/// Service for managing AI interactions with multiple providers
/// </summary>
public class AIService : IAIService
{
    private readonly HttpClient _httpClient;
    private readonly AIProviderManager _providerManager;
    private AIProvider _activeProvider = AIProvider.OpenAI;
    private string _apiKey = string.Empty;
    private string _selectedModel = "gpt-3.5-turbo";

    // Provider endpoints
    private readonly Dictionary<AIProvider, string> _endpoints = new()
    {
        { AIProvider.OpenAI, "https://api.openai.com/v1/chat/completions" },
        { AIProvider.Anthropic, "https://api.anthropic.com/v1/messages" },
        { AIProvider.DeepSeek, "https://api.deepseek.com/v1/chat/completions" },
        { AIProvider.Gemini, "https://generativelanguage.googleapis.com/v1beta/models/" },
        { AIProvider.Ollama, "http://localhost:11434/api/chat" },
        { AIProvider.GroqCloud, "https://api.groq.com/openai/v1/chat/completions" }
    };

    // Default models for each provider
    private readonly Dictionary<AIProvider, List<string>> _availableModels = new()
    {
        { AIProvider.OpenAI, new List<string> { "gpt-3.5-turbo", "gpt-4", "gpt-4-turbo", "gpt-4o" } },
        { AIProvider.Anthropic, new List<string> { "claude-3-5-sonnet-20241022", "claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307" } },
        { AIProvider.DeepSeek, new List<string> { "deepseek-chat", "deepseek-coder", "deepseek-reasoner" } },
        { AIProvider.Gemini, new List<string> { "gemini-2.0-flash-exp", "gemini-1.5-pro", "gemini-1.5-flash" } },
        { AIProvider.Ollama, new List<string> { "llama3.2", "llama3.1", "mistral", "phi3", "gemma2", "qwen2.5" } },
        { AIProvider.GroqCloud, new List<string> { "llama-3.3-70b-versatile", "llama-3.1-8b-instant", "mixtral-8x7b-32768", "gemma2-9b-it" } }
    };

    public AIService(HttpClient httpClient, AIProviderManager providerManager)
    {
        _httpClient = httpClient;
        _providerManager = providerManager;
        LoadActiveProvider();
    }

    /// <summary>
    /// Get the currently active AI provider
    /// </summary>
    public AIProvider ActiveProvider => _activeProvider;

    /// <summary>
    /// Get the currently selected model
    /// </summary>
    public string SelectedModel => _selectedModel;

    /// <summary>
    /// Set the active AI provider
    /// </summary>
    public void SetProvider(AIProvider provider, string apiKey)
    {
        _activeProvider = provider;
        _apiKey = apiKey;
        _selectedModel = _availableModels[provider].First();
        SaveProviderSettings();
    }

    /// <summary>
    /// Set the model for the current provider
    /// </summary>
    public void SetModel(string model)
    {
        if (_availableModels[_activeProvider].Contains(model))
        {
            _selectedModel = model;
            SaveProviderSettings();
        }
    }

    /// <summary>
    /// Get available models for a provider
    /// </summary>
    public List<string> GetAvailableModels(AIProvider provider)
    {
        return _availableModels.ContainsKey(provider)
            ? new List<string>(_availableModels[provider])
            : new List<string>();
    }

    /// <summary>
    /// Send a chat completion request to the active AI provider
    /// </summary>
    public async Task<AIResponse> SendChatCompletionAsync(
        List<ConversationMessage> messages,
        double temperature = 0.7,
        int maxTokens = 150,
        double topP = 1.0,
        double frequencyPenalty = 0.0,
        double presencePenalty = 0.0)
    {
        return _activeProvider switch
        {
            AIProvider.OpenAI => await SendOpenAIRequestAsync(messages, temperature, maxTokens, topP, frequencyPenalty, presencePenalty),
            AIProvider.Anthropic => await SendAnthropicRequestAsync(messages, temperature, maxTokens, topP),
            AIProvider.DeepSeek => await SendDeepSeekRequestAsync(messages, temperature, maxTokens, topP, frequencyPenalty, presencePenalty),
            AIProvider.Gemini => await SendGeminiRequestAsync(messages, temperature, maxTokens, topP),
            AIProvider.Ollama => await SendOllamaRequestAsync(messages, temperature, maxTokens),
            AIProvider.GroqCloud => await SendGroqRequestAsync(messages, temperature, maxTokens, topP),
            _ => throw new NotSupportedException($"Provider {_activeProvider} is not supported")
        };
    }

    /// <summary>
    /// Send request to OpenAI API
    /// </summary>
    private async Task<AIResponse> SendOpenAIRequestAsync(
        List<ConversationMessage> messages,
        double temperature,
        int maxTokens,
        double topP,
        double frequencyPenalty,
        double presencePenalty)
    {
        var requestBody = new
        {
            model = _selectedModel,
            messages = messages.Select(m => new
            {
                role = m.Role.ToLowerInvariant(),
                content = m.Content
            }),
            temperature,
            max_tokens = maxTokens,
            top_p = topP,
            frequency_penalty = frequencyPenalty,
            presence_penalty = presencePenalty
        };

        var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);

        try
        {
            var response = await _httpClient.PostAsync(_endpoints[AIProvider.OpenAI], content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                var jsonDoc = JsonDocument.Parse(responseContent);
                var choice = jsonDoc.RootElement.GetProperty("choices")[0];
                var message = choice.GetProperty("message");

                return new AIResponse
                {
                    Success = true,
                    Content = message.GetProperty("content").GetString() ?? string.Empty,
                    Provider = AIProvider.OpenAI,
                    Model = _selectedModel,
                    TokensUsed = jsonDoc.RootElement.GetProperty("usage").GetProperty("total_tokens").GetInt32()
                };
            }
            else
            {
                return new AIResponse
                {
                    Success = false,
                    Error = $"OpenAI API error: {response.StatusCode} - {responseContent}",
                    Provider = AIProvider.OpenAI,
                    Model = _selectedModel
                };
            }
        }
        catch (Exception ex)
        {
            return new AIResponse
            {
                Success = false,
                Error = $"Exception calling OpenAI API: {ex.Message}",
                Provider = AIProvider.OpenAI,
                Model = _selectedModel
            };
        }
    }

    /// <summary>
    /// Send request to Anthropic Claude API
    /// </summary>
    private async Task<AIResponse> SendAnthropicRequestAsync(
        List<ConversationMessage> messages,
        double temperature,
        int maxTokens,
        double topP)
    {
        var systemMessage = messages.FirstOrDefault(m => m.Role == "system")?.Content ?? "";
        var conversationMessages = messages.Where(m => m.Role != "system").Select(m => new
        {
            role = m.Role.ToLowerInvariant(),
            content = m.Content
        });

        var requestBody = new
        {
            model = _selectedModel,
            messages = conversationMessages,
            system = systemMessage,
            max_tokens = maxTokens,
            temperature,
            top_p = topP
        };

        var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Add("x-api-key", _apiKey);
        _httpClient.DefaultRequestHeaders.Add("anthropic-version", "2023-06-01");

        try
        {
            var response = await _httpClient.PostAsync(_endpoints[AIProvider.Anthropic], content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                var jsonDoc = JsonDocument.Parse(responseContent);
                var contentArray = jsonDoc.RootElement.GetProperty("content");
                var textContent = contentArray[0].GetProperty("text").GetString() ?? string.Empty;

                return new AIResponse
                {
                    Success = true,
                    Content = textContent,
                    Provider = AIProvider.Anthropic,
                    Model = _selectedModel,
                    TokensUsed = jsonDoc.RootElement.TryGetProperty("usage", out var usage)
                        ? usage.GetProperty("output_tokens").GetInt32() + usage.GetProperty("input_tokens").GetInt32()
                        : 0
                };
            }
            else
            {
                return new AIResponse
                {
                    Success = false,
                    Error = $"Anthropic API error: {response.StatusCode} - {responseContent}",
                    Provider = AIProvider.Anthropic,
                    Model = _selectedModel
                };
            }
        }
        catch (Exception ex)
        {
            return new AIResponse
            {
                Success = false,
                Error = $"Exception calling Anthropic API: {ex.Message}",
                Provider = AIProvider.Anthropic,
                Model = _selectedModel
            };
        }
    }

    /// <summary>
    /// Send request to DeepSeek API
    /// </summary>
    private async Task<AIResponse> SendDeepSeekRequestAsync(
        List<ConversationMessage> messages,
        double temperature,
        int maxTokens,
        double topP,
        double frequencyPenalty,
        double presencePenalty)
    {
        // DeepSeek uses OpenAI-compatible API
        return await SendOpenAIRequestAsync(messages, temperature, maxTokens, topP, frequencyPenalty, presencePenalty);
    }

    /// <summary>
    /// Send request to Google Gemini API
    /// </summary>
    private async Task<AIResponse> SendGeminiRequestAsync(
        List<ConversationMessage> messages,
        double temperature,
        int maxTokens,
        double topP)
    {
        var contents = messages.Select(m => new
        {
            role = m.Role == "assistant" ? "model" : "user",
            parts = new[] { new { text = m.Content } }
        });

        var requestBody = new
        {
            contents,
            generationConfig = new
            {
                temperature,
                topP,
                maxOutputTokens = maxTokens
            }
        };

        var endpoint = $"{_endpoints[AIProvider.Gemini]}{_selectedModel}:generateContent?key={_apiKey}";
        var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

        try
        {
            var response = await _httpClient.PostAsync(endpoint, content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                var jsonDoc = JsonDocument.Parse(responseContent);
                var candidates = jsonDoc.RootElement.GetProperty("candidates");
                var textContent = candidates[0].GetProperty("content").GetProperty("parts")[0].GetProperty("text").GetString() ?? string.Empty;

                return new AIResponse
                {
                    Success = true,
                    Content = textContent,
                    Provider = AIProvider.Gemini,
                    Model = _selectedModel,
                    TokensUsed = 0 // Gemini doesn't provide token count in response
                };
            }
            else
            {
                return new AIResponse
                {
                    Success = false,
                    Error = $"Gemini API error: {response.StatusCode} - {responseContent}",
                    Provider = AIProvider.Gemini,
                    Model = _selectedModel
                };
            }
        }
        catch (Exception ex)
        {
            return new AIResponse
            {
                Success = false,
                Error = $"Exception calling Gemini API: {ex.Message}",
                Provider = AIProvider.Gemini,
                Model = _selectedModel
            };
        }
    }

    /// <summary>
    /// Send request to Ollama (local, free)
    /// </summary>
    private async Task<AIResponse> SendOllamaRequestAsync(
        List<ConversationMessage> messages,
        double temperature,
        int maxTokens)
    {
        var requestBody = new
        {
            model = _selectedModel,
            messages = messages.Select(m => new
            {
                role = m.Role.ToLowerInvariant(),
                content = m.Content
            }),
            stream = false,
            options = new
            {
                temperature,
                num_predict = maxTokens
            }
        };

        var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

        try
        {
            var response = await _httpClient.PostAsync(_endpoints[AIProvider.Ollama], content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                var jsonDoc = JsonDocument.Parse(responseContent);
                var messageContent = jsonDoc.RootElement.GetProperty("message").GetProperty("content").GetString() ?? string.Empty;

                return new AIResponse
                {
                    Success = true,
                    Content = messageContent,
                    Provider = AIProvider.Ollama,
                    Model = _selectedModel,
                    TokensUsed = 0 // Ollama doesn't track tokens in the same way
                };
            }
            else
            {
                return new AIResponse
                {
                    Success = false,
                    Error = $"Ollama error: {response.StatusCode} - {responseContent}. Is Ollama running locally?",
                    Provider = AIProvider.Ollama,
                    Model = _selectedModel
                };
            }
        }
        catch (HttpRequestException)
        {
            return new AIResponse
            {
                Success = false,
                Error = "Cannot connect to Ollama. Please ensure Ollama is installed and running (https://ollama.ai)",
                Provider = AIProvider.Ollama,
                Model = _selectedModel
            };
        }
        catch (Exception ex)
        {
            return new AIResponse
            {
                Success = false,
                Error = $"Exception calling Ollama: {ex.Message}",
                Provider = AIProvider.Ollama,
                Model = _selectedModel
            };
        }
    }

    /// <summary>
    /// Send request to Groq Cloud (free tier available, very fast)
    /// </summary>
    private async Task<AIResponse> SendGroqRequestAsync(
        List<ConversationMessage> messages,
        double temperature,
        int maxTokens,
        double topP)
    {
        // Groq uses OpenAI-compatible API
        var requestBody = new
        {
            model = _selectedModel,
            messages = messages.Select(m => new
            {
                role = m.Role.ToLowerInvariant(),
                content = m.Content
            }),
            temperature,
            max_tokens = maxTokens,
            top_p = topP
        };

        var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);

        try
        {
            var response = await _httpClient.PostAsync(_endpoints[AIProvider.GroqCloud], content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                var jsonDoc = JsonDocument.Parse(responseContent);
                var choice = jsonDoc.RootElement.GetProperty("choices")[0];
                var message = choice.GetProperty("message");

                return new AIResponse
                {
                    Success = true,
                    Content = message.GetProperty("content").GetString() ?? string.Empty,
                    Provider = AIProvider.GroqCloud,
                    Model = _selectedModel,
                    TokensUsed = jsonDoc.RootElement.TryGetProperty("usage", out var usage)
                        ? usage.GetProperty("total_tokens").GetInt32()
                        : 0
                };
            }
            else
            {
                return new AIResponse
                {
                    Success = false,
                    Error = $"Groq API error: {response.StatusCode} - {responseContent}",
                    Provider = AIProvider.GroqCloud,
                    Model = _selectedModel
                };
            }
        }
        catch (Exception ex)
        {
            return new AIResponse
            {
                Success = false,
                Error = $"Exception calling Groq API: {ex.Message}",
                Provider = AIProvider.GroqCloud,
                Model = _selectedModel
            };
        }
    }

    /// <summary>
    /// Test the connection to the current AI provider
    /// </summary>
    public async Task<bool> TestConnectionAsync()
    {
        var testMessages = new List<ConversationMessage>
        {
            new() { Role = "user", Content = "Say 'test successful' if you can hear me." }
        };

        var response = await SendChatCompletionAsync(testMessages, 0.1, 10);
        return response.Success;
    }

    /// <summary>
    /// Load active provider settings
    /// </summary>
    private void LoadActiveProvider()
    {
        var config = _providerManager.GetActiveProvider();
        if (config != null)
        {
            _activeProvider = config.Provider;
            _apiKey = config.ApiKey;
            _selectedModel = config.SelectedModel;
        }
    }

    /// <summary>
    /// Save provider settings
    /// </summary>
    private void SaveProviderSettings()
    {
        _providerManager.UpdateProvider(new AIProviderConfig
        {
            Provider = _activeProvider,
            ApiKey = _apiKey,
            SelectedModel = _selectedModel,
            IsActive = true
        });
    }
}

/// <summary>
/// AI provider types
/// </summary>
public enum AIProvider
{
    OpenAI,
    Anthropic,
    DeepSeek,
    Gemini,
    Ollama,        // Free - runs locally
    GroqCloud      // Free tier available
}

/// <summary>
/// AI response model
/// </summary>
public class AIResponse
{
    public bool Success { get; set; }
    public string Content { get; set; } = string.Empty;
    public string Error { get; set; } = string.Empty;
    public AIProvider Provider { get; set; }
    public string Model { get; set; } = string.Empty;
    public int TokensUsed { get; set; }
}

/// <summary>
/// AI provider configuration
/// </summary>
public class AIProviderConfig
{
    public AIProvider Provider { get; set; }
    public string ApiKey { get; set; } = string.Empty;
    public string SelectedModel { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public Dictionary<string, object> Settings { get; set; } = new();
}

/// <summary>
/// Interface for AI service
/// </summary>
public interface IAIService
{
    AIProvider ActiveProvider { get; }
    string SelectedModel { get; }
    void SetProvider(AIProvider provider, string apiKey);
    void SetModel(string model);
    List<string> GetAvailableModels(AIProvider provider);
    Task<AIResponse> SendChatCompletionAsync(
        List<ConversationMessage> messages,
        double temperature = 0.7,
        int maxTokens = 150,
        double topP = 1.0,
        double frequencyPenalty = 0.0,
        double presencePenalty = 0.0);
    Task<bool> TestConnectionAsync();
}