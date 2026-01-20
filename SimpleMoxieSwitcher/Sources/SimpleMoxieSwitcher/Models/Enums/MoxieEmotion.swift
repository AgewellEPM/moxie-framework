import SwiftUI

enum MoxieEmotion: String, CaseIterable {
    case happy = "happy"
    case sad = "sad"
    case angry = "angry"
    case surprised = "surprised"
    case neutral = "neutral"
    case excited = "excited"
    case sleepy = "sleepy"
    case confused = "confused"

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .angry: return "😠"
        case .surprised: return "😲"
        case .neutral: return "😐"
        case .excited: return "🤩"
        case .sleepy: return "😴"
        case .confused: return "😕"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .happy: return Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
        case .sad: return Color(red: 0.3, green: 0.5, blue: 0.9) // Blue
        case .angry: return Color(red: 0.9, green: 0.2, blue: 0.2) // Red
        case .surprised: return Color(red: 1.0, green: 0.6, blue: 0.2) // Orange
        case .neutral: return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        case .excited: return Color(red: 0.9, green: 0.3, blue: 0.9) // Purple
        case .sleepy: return Color(red: 0.4, green: 0.3, blue: 0.6) // Dark blue
        case .confused: return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown
        }
    }
}