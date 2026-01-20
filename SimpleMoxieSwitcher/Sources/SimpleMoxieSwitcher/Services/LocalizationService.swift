import Foundation
import SwiftUI

class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published var currentLanguage: Language

    private init() {
        let current = LanguagePreferenceManager.shared.currentLanguage
        // Find matching language from Language.allLanguages
        if let lang = Language.allLanguages.first(where: { $0.code == current.code }) {
            self.currentLanguage = lang
        } else {
            // Fallback - create default Language
            let flag = LocalizationService.getFlagStatic(for: current.code)
            self.currentLanguage = Language(code: current.code, name: current.name, flag: flag)
        }

        // Listen for language changes
        NotificationCenter.default.addObserver(self, selector: #selector(languageChanged), name: .moxieLanguageChanged, object: nil)
    }

    @objc private func languageChanged() {
        let current = LanguagePreferenceManager.shared.currentLanguage
        // Find matching language from Language.allLanguages
        if let lang = Language.allLanguages.first(where: { $0.code == current.code }) {
            currentLanguage = lang
        } else {
            let flag = LocalizationService.getFlagStatic(for: current.code)
            currentLanguage = Language(code: current.code, name: current.name, flag: flag)
        }

        // Force UI update
        objectWillChange.send()
    }

    func localize(_ key: String) -> String {
        let translations = getTranslations()
        return translations[currentLanguage.code]?[key] ?? translations["en"]?[key] ?? key
    }

    func forceLanguageUpdate(_ language: Language) {
        self.currentLanguage = language
        objectWillChange.send()
    }

    static func getFlagStatic(for code: String) -> String {
        switch code {
        case "en": return "🇺🇸"
        case "es": return "🇪🇸"
        case "zh": return "🇨🇳"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "sv": return "🇸🇪"
        case "it": return "🇮🇹"
        case "ru": return "🇷🇺"
        case "ja": return "🇯🇵"
        default: return "🌍"
        }
    }

    private func getTranslations() -> [String: [String: String]] {
        return [
            "en": [
                // Main UI
                "moxie_controller": "OpenMoxie Controller",
                "online": "Online",
                "offline": "Offline",
                "switching_personality": "Switching personality...",

                // Feature buttons
                "custom_creator": "Custom Personality",
                "child_profile": "Child Profile",
                "appearance": "Appearance",
                "chat": "Conversations",
                "story_time": "Story Time",
                "learning": "Learning",
                "language": "Language",
                "music": "Music",
                "smart_home": "Smart Home",
                "puppet_mode": "Puppet Mode",
                "lyric_mode": "Lyric Mode",
                "settings": "Settings",
                "start_docker": "Start Docker",
                "documentation": "Documentation",
                "games": "Games",

                // Settings
                "moxie_endpoint": "Moxie Endpoint",
                "docker_settings": "Docker Settings",
                "ai_providers": "AI Providers",
                "save": "Save",
                "cancel": "Cancel",
                "close": "Close",

                // Chat
                "type_message": "Type a message...",
                "send": "Send",
                "new_conversation": "New Conversation",

                // Learning
                "math": "Math",
                "science": "Science",
                "history": "History",
                "quiz": "Quiz",
                "next_question": "Next Question",

                // Story
                "choose_story": "Choose a story",
                "create_story": "Create your own story",
                "continue": "Continue",

                // Personality Names
                "Default OpenMoxie": "Default OpenMoxie",
                "Default Moxie": "Default OpenMoxie",
                "Ben Stein Mode": "Ben Stein Mode",
                "2Pac Moxie": "2Pac Moxie",
                "Roast Mode": "Roast Mode",
                "Freestyle Rapper": "Freestyle Rapper",
                "Motivational Coach": "Motivational Coach",
                "Shakespeare Mode": "Shakespeare Mode",
                "Valley Girl": "Valley Girl",
                "Pirate Mode": "Pirate Mode",
                "Yoda Mode": "Yoda Mode"
            ],
            "es": [
                // Main UI
                "moxie_controller": "Controlador OpenMoxie",
                "online": "En línea",
                "offline": "Fuera de línea",
                "switching_personality": "Cambiando personalidad...",

                // Feature buttons
                "custom_creator": "Personalidad Personalizada",
                "child_profile": "Perfil del Niño",
                "appearance": "Apariencia",
                "chat": "Conversaciones",
                "story_time": "Hora del Cuento",
                "learning": "Aprendizaje",
                "language": "Idioma",
                "music": "Música",
                "smart_home": "Hogar Inteligente",
                "puppet_mode": "Modo Títere",
                "lyric_mode": "Modo Letra",
                "settings": "Configuración",
                "start_docker": "Iniciar Docker",
                "documentation": "Documentación",
                "games": "Juegos",

                // Settings
                "moxie_endpoint": "Punto Final de Moxie",
                "docker_settings": "Configuración de Docker",
                "ai_providers": "Proveedores de IA",
                "save": "Guardar",
                "cancel": "Cancelar",
                "close": "Cerrar",

                // Chat
                "type_message": "Escribe un mensaje...",
                "send": "Enviar",
                "new_conversation": "Nueva Conversación",

                // Learning
                "math": "Matemáticas",
                "science": "Ciencia",
                "history": "Historia",
                "quiz": "Cuestionario",
                "next_question": "Siguiente Pregunta",

                // Story
                "choose_story": "Elige una historia",
                "create_story": "Crea tu propia historia",
                "continue": "Continuar",

                // Personality Names (Spanish)
                "Default OpenMoxie": "OpenMoxie Predeterminado",
                "Default Moxie": "OpenMoxie Predeterminado",
                "Ben Stein Mode": "Modo Ben Stein",
                "2Pac Moxie": "Moxie 2Pac",
                "Roast Mode": "Modo Asado",
                "Freestyle Rapper": "Rapero Freestyle",
                "Motivational Coach": "Entrenador Motivacional",
                "Shakespeare Mode": "Modo Shakespeare",
                "Valley Girl": "Chica del Valle",
                "Pirate Mode": "Modo Pirata",
                "Yoda Mode": "Modo Yoda"
            ],
            "zh": [
                // Main UI
                "moxie_controller": "OpenMoxie 控制器",
                "online": "在线",
                "offline": "离线",
                "switching_personality": "切换个性中...",

                // Feature buttons
                "custom_creator": "自定义创建",
                "child_profile": "儿童档案",
                "appearance": "外观",
                "chat": "聊天",
                "story_time": "故事时间",
                "learning": "学习",
                "language": "语言",
                "music": "音乐",
                "smart_home": "智能家居",
                "puppet_mode": "木偶模式",
                "lyric_mode": "歌词模式",
                "settings": "设置",
                "start_docker": "启动 Docker",
                "documentation": "文档",
                "games": "游戏",

                // Settings
                "moxie_endpoint": "Moxie 端点",
                "docker_settings": "Docker 设置",
                "ai_providers": "AI 提供商",
                "save": "保存",
                "cancel": "取消",
                "close": "关闭",

                // Chat
                "type_message": "输入消息...",
                "send": "发送",
                "new_conversation": "新对话",

                // Learning
                "math": "数学",
                "science": "科学",
                "history": "历史",
                "quiz": "测验",
                "next_question": "下一题",

                // Story
                "choose_story": "选择一个故事",
                "create_story": "创建你自己的故事",
                "continue": "继续"
            ],
            "fr": [
                // Main UI
                "moxie_controller": "Contrôleur OpenMoxie",
                "online": "En ligne",
                "offline": "Hors ligne",
                "switching_personality": "Changement de personnalité...",

                // Feature buttons
                "custom_creator": "Créateur Personnalisé",
                "child_profile": "Profil de l'Enfant",
                "appearance": "Apparence",
                "chat": "Discuter",
                "story_time": "L'heure du Conte",
                "learning": "Apprentissage",
                "language": "Langue",
                "music": "Musique",
                "smart_home": "Maison Intelligente",
                "puppet_mode": "Mode Marionnette",
                "lyric_mode": "Mode Paroles",
                "settings": "Paramètres",
                "start_docker": "Démarrer Docker",
                "documentation": "Documentation",
                "games": "Jeux",

                // Settings
                "moxie_endpoint": "Point de Terminaison Moxie",
                "docker_settings": "Paramètres Docker",
                "ai_providers": "Fournisseurs d'IA",
                "save": "Sauvegarder",
                "cancel": "Annuler",
                "close": "Fermer",

                // Chat
                "type_message": "Tapez un message...",
                "send": "Envoyer",
                "new_conversation": "Nouvelle Conversation",

                // Learning
                "math": "Mathématiques",
                "science": "Science",
                "history": "Histoire",
                "quiz": "Quiz",
                "next_question": "Question Suivante",

                // Story
                "choose_story": "Choisissez une histoire",
                "create_story": "Créez votre propre histoire",
                "continue": "Continuer"
            ],
            "de": [
                // Main UI
                "moxie_controller": "OpenMoxie Steuerung",
                "online": "Online",
                "offline": "Offline",
                "switching_personality": "Persönlichkeit wechseln...",

                // Feature buttons
                "custom_creator": "Eigener Ersteller",
                "child_profile": "Kinderprofil",
                "appearance": "Aussehen",
                "chat": "Chat",
                "story_time": "Geschichtenzeit",
                "learning": "Lernen",
                "language": "Sprache",
                "music": "Musik",
                "smart_home": "Smart Home",
                "puppet_mode": "Puppenmodus",
                "lyric_mode": "Liedtext-Modus",
                "settings": "Einstellungen",
                "start_docker": "Docker Starten",
                "documentation": "Dokumentation",
                "games": "Spiele",

                // Settings
                "moxie_endpoint": "Moxie Endpunkt",
                "docker_settings": "Docker Einstellungen",
                "ai_providers": "KI-Anbieter",
                "save": "Speichern",
                "cancel": "Abbrechen",
                "close": "Schließen",

                // Chat
                "type_message": "Nachricht eingeben...",
                "send": "Senden",
                "new_conversation": "Neue Unterhaltung",

                // Learning
                "math": "Mathematik",
                "science": "Wissenschaft",
                "history": "Geschichte",
                "quiz": "Quiz",
                "next_question": "Nächste Frage",

                // Story
                "choose_story": "Wähle eine Geschichte",
                "create_story": "Erstelle deine eigene Geschichte",
                "continue": "Weiter"
            ],
            "sv": [
                // Main UI
                "moxie_controller": "OpenMoxie Kontroller",
                "online": "Online",
                "offline": "Offline",
                "switching_personality": "Byter personlighet...",

                // Feature buttons
                "custom_creator": "Anpassad Personlighet",
                "child_profile": "Barnprofil",
                "appearance": "Utseende",
                "chat": "Konversationer",
                "story_time": "Sagostund",
                "learning": "Lärande",
                "language": "Språk",
                "music": "Musik",
                "smart_home": "Smart Hem",
                "puppet_mode": "Docka Läge",
                "lyric_mode": "Sångtext Läge",
                "settings": "Inställningar",
                "start_docker": "Starta Docker",
                "documentation": "Dokumentation",
                "games": "Spel",

                // Settings
                "moxie_endpoint": "Moxie Slutpunkt",
                "docker_settings": "Docker Inställningar",
                "ai_providers": "AI Leverantörer",
                "save": "Spara",
                "cancel": "Avbryt",
                "close": "Stäng",

                // Chat
                "type_message": "Skriv ett meddelande...",
                "send": "Skicka",
                "new_conversation": "Ny Konversation",

                // Learning
                "math": "Matematik",
                "science": "Vetenskap",
                "history": "Historia",
                "quiz": "Quiz",
                "next_question": "Nästa Fråga",

                // Story
                "choose_story": "Välj en saga",
                "create_story": "Skapa din egen saga",
                "continue": "Fortsätt",

                // Personality Names (Swedish)
                "Default OpenMoxie": "Standard OpenMoxie",
                "Default Moxie": "Standard OpenMoxie",
                "Ben Stein Mode": "Ben Stein-läge",
                "2Pac Moxie": "2Pac Moxie",
                "Roast Mode": "Grill-läge",
                "Freestyle Rapper": "Freestyle-rappare",
                "Motivational Coach": "Motivationscoach",
                "Shakespeare Mode": "Shakespeare-läge",
                "Valley Girl": "Valley Girl",
                "Pirate Mode": "Pirat-läge",
                "Yoda Mode": "Yoda-läge"
            ],
            "it": [
                // Main UI
                "moxie_controller": "Controller OpenMoxie",
                "online": "Online",
                "offline": "Offline",
                "switching_personality": "Cambio personalità...",

                // Feature buttons
                "custom_creator": "Creatore Personalizzato",
                "child_profile": "Profilo Bambino",
                "appearance": "Aspetto",
                "chat": "Chat",
                "story_time": "Ora delle Storie",
                "learning": "Apprendimento",
                "language": "Lingua",
                "music": "Musica",
                "smart_home": "Casa Intelligente",
                "puppet_mode": "Modalità Marionetta",
                "lyric_mode": "Modalità Testi",
                "settings": "Impostazioni",
                "start_docker": "Avvia Docker",
                "documentation": "Documentazione",
                "games": "Giochi",

                // Settings
                "moxie_endpoint": "Endpoint Moxie",
                "docker_settings": "Impostazioni Docker",
                "ai_providers": "Fornitori AI",
                "save": "Salva",
                "cancel": "Annulla",
                "close": "Chiudi",

                // Chat
                "type_message": "Scrivi un messaggio...",
                "send": "Invia",
                "new_conversation": "Nuova Conversazione",

                // Learning
                "math": "Matematica",
                "science": "Scienze",
                "history": "Storia",
                "quiz": "Quiz",
                "next_question": "Prossima Domanda",

                // Story
                "choose_story": "Scegli una storia",
                "create_story": "Crea la tua storia",
                "continue": "Continua"
            ],
            "ru": [
                // Main UI
                "moxie_controller": "Контроллер OpenMoxie",
                "online": "Онлайн",
                "offline": "Офлайн",
                "switching_personality": "Смена личности...",

                // Feature buttons
                "custom_creator": "Создатель",
                "child_profile": "Профиль Ребёнка",
                "appearance": "Внешний вид",
                "chat": "Чат",
                "story_time": "Время Историй",
                "learning": "Обучение",
                "language": "Язык",
                "music": "Музыка",
                "smart_home": "Умный Дом",
                "puppet_mode": "Режим Марионетки",
                "lyric_mode": "Режим Текста",
                "settings": "Настройки",
                "start_docker": "Запустить Docker",
                "documentation": "Документация",
                "games": "Игры",

                // Settings
                "moxie_endpoint": "Конечная точка Moxie",
                "docker_settings": "Настройки Docker",
                "ai_providers": "Провайдеры ИИ",
                "save": "Сохранить",
                "cancel": "Отмена",
                "close": "Закрыть",

                // Chat
                "type_message": "Введите сообщение...",
                "send": "Отправить",
                "new_conversation": "Новая Беседа",

                // Learning
                "math": "Математика",
                "science": "Наука",
                "history": "История",
                "quiz": "Викторина",
                "next_question": "Следующий Вопрос",

                // Story
                "choose_story": "Выберите историю",
                "create_story": "Создайте свою историю",
                "continue": "Продолжить"
            ],
            "ja": [
                // Main UI
                "moxie_controller": "OpenMoxie コントローラー",
                "online": "オンライン",
                "offline": "オフライン",
                "switching_personality": "パーソナリティを切り替え中...",

                // Feature buttons
                "custom_creator": "カスタムクリエーター",
                "child_profile": "子供プロフィール",
                "appearance": "外観",
                "chat": "チャット",
                "story_time": "お話の時間",
                "learning": "学習",
                "language": "言語",
                "music": "音楽",
                "smart_home": "スマートホーム",
                "puppet_mode": "人形モード",
                "lyric_mode": "歌詞モード",
                "settings": "設定",
                "start_docker": "Docker を起動",
                "documentation": "ドキュメント",
                "games": "ゲーム",

                // Settings
                "moxie_endpoint": "Moxie エンドポイント",
                "docker_settings": "Docker 設定",
                "ai_providers": "AI プロバイダー",
                "save": "保存",
                "cancel": "キャンセル",
                "close": "閉じる",

                // Chat
                "type_message": "メッセージを入力...",
                "send": "送信",
                "new_conversation": "新しい会話",

                // Learning
                "math": "数学",
                "science": "科学",
                "history": "歴史",
                "quiz": "クイズ",
                "next_question": "次の質問",

                // Story
                "choose_story": "物語を選ぶ",
                "create_story": "あなた自身の物語を作る",
                "continue": "続ける"
            ]
        ]
    }
}

// Extension for easy use
extension String {
    func localized() -> String {
        LocalizationService.shared.localize(self)
    }
}