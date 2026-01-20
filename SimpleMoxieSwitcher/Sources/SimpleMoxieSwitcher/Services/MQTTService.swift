import Foundation
import CocoaMQTT

final class MQTTService: MQTTServiceProtocol {
    private var mqtt: CocoaMQTT?
    private let deviceId = "d_openmoxie_ios"
    private let clientId: String

    init() {
        self.clientId = "SimpleMoxieSwitcher-\(UUID().uuidString)"
        setupMQTT()
    }

    private func setupMQTT() {
        let host = AppConfig.mqttHost
        let port = UInt16(AppConfig.mqttPort)
        let useTLS = AppConfig.mqttUseTLS

        mqtt = CocoaMQTT(clientID: clientId, host: host, port: port)
        guard let mqtt = mqtt else { return }

        mqtt.username = "unknown"
        mqtt.password = ""
        mqtt.keepAlive = 60
        mqtt.autoReconnect = true
        mqtt.enableSSL = useTLS
        mqtt.allowUntrustCACertificate = useTLS  // Allow self-signed certificates when TLS is on

        // Set delegate to handle connection events
        mqtt.delegate = self

        print("MQTT configured for host: \(host):\(port) TLS=\(useTLS)")
    }

    func connect() {
        _ = mqtt?.connect()
    }

    func disconnect() {
        mqtt?.disconnect()
    }

    func sendCommand(_ command: String, speech: String) {
        guard let mqtt = mqtt else { return }

        // OpenMoxie expects remote-chat events, not volley commands
        // The proper format is:
        // - Send TO: /devices/{deviceId}/events/remote-chat
        // - Receive FROM: /devices/{deviceId}/commands/remote_chat

        let payload: [String: Any] = [
            "event_id": UUID().uuidString,
            "command": speech.isEmpty ? "prompt" : "continue",
            "speech": speech,
            "backend": "router",
            "module_id": "OPENMOXIE_CHAT",
            "content_id": "default"
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Send to events/remote-chat topic (this is what OpenMoxie expects)
            let topic = "/devices/\(deviceId)/events/remote-chat"
            mqtt.publish(topic, withString: jsonString, qos: .qos1)
            print("📤 Sent remote-chat event: \(speech)")
        }
    }

    func publish(topic: String, message: String) {
        mqtt?.publish(topic, withString: message, qos: .qos1)
    }
}

// MARK: - CocoaMQTTDelegate
extension MQTTService: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            print("✅ MQTT connected successfully")
            // Subscribe to command responses from OpenMoxie
            mqtt.subscribe("/devices/\(deviceId)/commands/remote_chat", qos: .qos1)
            mqtt.subscribe("/devices/\(deviceId)/commands/+", qos: .qos1)
            // Subscribe to wake word topic
            mqtt.subscribe("/devices/\(deviceId)/wakeword", qos: .qos1)
            print("📡 Subscribed to command topics")
        } else {
            print("⚠️ MQTT connection failed: \(ack)")
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        print("MQTT state changed to: \(state)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("MQTT published message with id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        // Message acknowledged
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        if let messageString = message.string {
            print("📥 MQTT received on \(message.topic)")

            // Parse OpenMoxie remote_chat responses
            if message.topic.contains("/commands/remote_chat") {
                if let data = messageString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    // Extract the response text
                    if let output = json["output"] as? [String: Any],
                       let text = output["text"] as? String {
                        print("🤖 Moxie response: \(text)")
                    }

                    // Extract response actions (for face control, movements, etc.)
                    if let responseActions = json["response_actions"] as? [[String: Any]] {
                        for action in responseActions {
                            if let actionName = action["action"] as? String {
                                print("🎬 Action: \(actionName)")

                                // Handle execute actions (face control, movements)
                                if actionName == "execute",
                                   let functionId = action["function_id"] as? String {
                                    print("⚙️ Execute function: \(functionId)")
                                    if let functionArgs = action["function_args"] as? [String: Any] {
                                        print("   Args: \(functionArgs)")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            print("   Raw: \(messageString)")
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print("MQTT subscribed to topics: \(success)")
        if !failed.isEmpty {
            print("MQTT failed to subscribe to: \(failed)")
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print("MQTT unsubscribed from topics: \(topics)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        // Ping sent
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        // Pong received
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        if let error = err {
            print("MQTT disconnected with error: \(error)")
        } else {
            print("MQTT disconnected normally")
        }
    }
}
