using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Extensions.ManagedClient;
using MQTTnet.Packets;
using MQTTnet.Protocol;
using Newtonsoft.Json;
using SimpleMoxieSwitcher.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace SimpleMoxieSwitcher.Services;

public class MQTTService : IMQTTService
{
    private readonly IManagedMqttClient _mqttClient;
    private readonly string _deviceId = "d_openmoxie_windows";
    private readonly string _clientId;

    public event EventHandler<MqttMessageEventArgs>? MessageReceived;
    public event EventHandler<bool>? ConnectionStatusChanged;

    public bool IsConnected => _mqttClient.IsConnected;

    public MQTTService()
    {
        _clientId = $"SimpleMoxieSwitcher-{Guid.NewGuid()}";
        _mqttClient = new MqttFactory().CreateManagedMqttClient();
        SetupMQTT();
    }

    private void SetupMQTT()
    {
        _mqttClient.ApplicationMessageReceivedAsync += OnMessageReceivedAsync;
        _mqttClient.ConnectedAsync += OnConnectedAsync;
        _mqttClient.DisconnectedAsync += OnDisconnectedAsync;
    }

    public async Task ConnectAsync()
    {
        var options = new ManagedMqttClientOptionsBuilder()
            .WithAutoReconnectDelay(TimeSpan.FromSeconds(5))
            .WithClientOptions(new MqttClientOptionsBuilder()
                .WithTcpServer("localhost", 8883)
                .WithClientId(_clientId)
                .WithCredentials("unknown", "")
                .WithTls(new MqttClientOptionsBuilderTlsParameters
                {
                    UseTls = true,
                    AllowUntrustedCertificates = true,
                    IgnoreCertificateChainErrors = true,
                    IgnoreCertificateRevocationErrors = true
                })
                .WithKeepAlivePeriod(TimeSpan.FromSeconds(60))
                .Build())
            .Build();

        await _mqttClient.StartAsync(options);
    }

    public async Task DisconnectAsync()
    {
        await _mqttClient.StopAsync();
    }

    public async Task SendCommandAsync(string command, string speech)
    {
        var payload = new Dictionary<string, object>
        {
            ["event_id"] = Guid.NewGuid().ToString(),
            ["command"] = string.IsNullOrEmpty(speech) ? "prompt" : "continue",
            ["speech"] = speech,
            ["backend"] = "router",
            ["module_id"] = "OPENMOXIE_CHAT",
            ["content_id"] = "default"
        };

        var jsonPayload = JsonConvert.SerializeObject(payload);
        var topic = $"/devices/{_deviceId}/events/remote-chat";

        var message = new MqttApplicationMessageBuilder()
            .WithTopic(topic)
            .WithPayload(jsonPayload)
            .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
            .Build();

        await _mqttClient.EnqueueAsync(message);
        Console.WriteLine($"📤 Sent remote-chat event: {speech}");
    }

    public async Task PublishAsync(string topic, string message)
    {
        var mqttMessage = new MqttApplicationMessageBuilder()
            .WithTopic(topic)
            .WithPayload(message)
            .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
            .Build();

        await _mqttClient.EnqueueAsync(mqttMessage);
    }

    private async Task OnConnectedAsync(MqttClientConnectedEventArgs e)
    {
        Console.WriteLine("✅ MQTT connected successfully");

        // Subscribe to command responses from OpenMoxie
        var topics = new List<MqttTopicFilter>
        {
            new MqttTopicFilterBuilder()
                .WithTopic($"/devices/{_deviceId}/commands/remote_chat")
                .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
                .Build(),
            new MqttTopicFilterBuilder()
                .WithTopic($"/devices/{_deviceId}/commands/+")
                .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
                .Build(),
            new MqttTopicFilterBuilder()
                .WithTopic($"/devices/{_deviceId}/wakeword")
                .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
                .Build()
        };

        await _mqttClient.SubscribeAsync(topics);
        Console.WriteLine("📡 Subscribed to command topics");

        ConnectionStatusChanged?.Invoke(this, true);
    }

    private Task OnDisconnectedAsync(MqttClientDisconnectedEventArgs e)
    {
        if (e.Exception != null)
        {
            Console.WriteLine($"MQTT disconnected with error: {e.Exception.Message}");
        }
        else
        {
            Console.WriteLine("MQTT disconnected normally");
        }

        ConnectionStatusChanged?.Invoke(this, false);
        return Task.CompletedTask;
    }

    private Task OnMessageReceivedAsync(MqttApplicationMessageReceivedEventArgs e)
    {
        var topic = e.ApplicationMessage.Topic;
        var payload = Encoding.UTF8.GetString(e.ApplicationMessage.Payload ?? Array.Empty<byte>());

        Console.WriteLine($"📥 MQTT received on {topic}");

        // Parse OpenMoxie remote_chat responses
        if (topic.Contains("/commands/remote_chat"))
        {
            try
            {
                dynamic? json = JsonConvert.DeserializeObject(payload);
                if (json != null)
                {
                    // Extract the response text
                    if (json.output?.text != null)
                    {
                        Console.WriteLine($"🤖 Moxie response: {json.output.text}");
                    }

                    // Extract response actions (for face control, movements, etc.)
                    if (json.response_actions != null)
                    {
                        foreach (var action in json.response_actions)
                        {
                            if (action.action != null)
                            {
                                Console.WriteLine($"🎬 Action: {action.action}");

                                // Handle execute actions (face control, movements)
                                if (action.action == "execute" && action.function_id != null)
                                {
                                    Console.WriteLine($"⚙️ Execute function: {action.function_id}");
                                    if (action.function_args != null)
                                    {
                                        Console.WriteLine($"   Args: {action.function_args}");
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error parsing MQTT message: {ex.Message}");
            }
        }

        Console.WriteLine($"   Raw: {payload}");

        MessageReceived?.Invoke(this, new MqttMessageEventArgs
        {
            Topic = topic,
            Payload = payload
        });

        return Task.CompletedTask;
    }
}

public class MqttMessageEventArgs : EventArgs
{
    public string Topic { get; set; } = string.Empty;
    public string Payload { get; set; } = string.Empty;
}