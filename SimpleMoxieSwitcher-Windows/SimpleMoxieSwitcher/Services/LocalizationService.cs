using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for managing multi-language localization
    /// </summary>
    public class LocalizationService : INotifyPropertyChanged
    {
        private static LocalizationService _instance;
        public static LocalizationService Instance => _instance ??= new LocalizationService();

        private Language _currentLanguage;
        public Language CurrentLanguage
        {
            get => _currentLanguage;
            set
            {
                if (_currentLanguage?.Code != value?.Code)
                {
                    _currentLanguage = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(Translations));
                }
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        private LocalizationService()
        {
            _currentLanguage = new Language { Code = "en", Name = "English", Flag = "🇺🇸" };
        }

        public string Localize(string key)
        {
            var translations = GetTranslations();
            if (translations.ContainsKey(CurrentLanguage.Code) &&
                translations[CurrentLanguage.Code].ContainsKey(key))
            {
                return translations[CurrentLanguage.Code][key];
            }

            // Fallback to English
            if (translations.ContainsKey("en") &&
                translations["en"].ContainsKey(key))
            {
                return translations["en"][key];
            }

            return key; // Return key if no translation found
        }

        public Dictionary<string, string> Translations
        {
            get
            {
                var allTranslations = GetTranslations();
                return allTranslations.ContainsKey(CurrentLanguage.Code)
                    ? allTranslations[CurrentLanguage.Code]
                    : allTranslations["en"];
            }
        }

        public static string GetFlag(string code)
        {
            return code switch
            {
                "en" => "🇺🇸",
                "es" => "🇪🇸",
                "zh" => "🇨🇳",
                "fr" => "🇫🇷",
                "de" => "🇩🇪",
                "sv" => "🇸🇪",
                "it" => "🇮🇹",
                "ru" => "🇷🇺",
                "ja" => "🇯🇵",
                _ => "🌍"
            };
        }

        private Dictionary<string, Dictionary<string, string>> GetTranslations()
        {
            return new Dictionary<string, Dictionary<string, string>>
            {
                ["en"] = new()
                {
                    // Main UI
                    ["moxie_controller"] = "OpenMoxie Controller",
                    ["online"] = "Online",
                    ["offline"] = "Offline",
                    ["switching_personality"] = "Switching personality...",

                    // Feature buttons
                    ["custom_creator"] = "Custom Personality",
                    ["child_profile"] = "Child Profile",
                    ["appearance"] = "Appearance",
                    ["chat"] = "Conversations",
                    ["story_time"] = "Story Time",
                    ["learning"] = "Learning",
                    ["language"] = "Language",
                    ["music"] = "Music",
                    ["smart_home"] = "Smart Home",
                    ["puppet_mode"] = "Puppet Mode",
                    ["settings"] = "Settings",
                    ["start_docker"] = "Start Docker",
                    ["documentation"] = "Documentation",
                    ["games"] = "Games",

                    // Settings
                    ["moxie_endpoint"] = "Moxie Endpoint",
                    ["docker_settings"] = "Docker Settings",
                    ["ai_providers"] = "AI Providers",
                    ["save"] = "Save",
                    ["cancel"] = "Cancel",
                    ["close"] = "Close",

                    // Chat
                    ["type_message"] = "Type a message...",
                    ["send"] = "Send",
                    ["new_conversation"] = "New Conversation",

                    // Learning
                    ["math"] = "Math",
                    ["science"] = "Science",
                    ["history"] = "History",
                    ["quiz"] = "Quiz",
                    ["next_question"] = "Next Question",

                    // Story
                    ["choose_story"] = "Choose a story",
                    ["create_story"] = "Create your own story",
                    ["continue"] = "Continue",

                    // Personality Names
                    ["Default Moxie"] = "Default Moxie",
                    ["Motivational Coach"] = "Motivational Coach",
                    ["Pirate Mode"] = "Pirate Mode"
                },

                ["es"] = new()
                {
                    // Main UI
                    ["moxie_controller"] = "Controlador OpenMoxie",
                    ["online"] = "En línea",
                    ["offline"] = "Fuera de línea",
                    ["switching_personality"] = "Cambiando personalidad...",

                    // Feature buttons
                    ["custom_creator"] = "Personalidad Personalizada",
                    ["child_profile"] = "Perfil del Niño",
                    ["appearance"] = "Apariencia",
                    ["chat"] = "Conversaciones",
                    ["story_time"] = "Hora del Cuento",
                    ["learning"] = "Aprendizaje",
                    ["language"] = "Idioma",
                    ["music"] = "Música",
                    ["smart_home"] = "Hogar Inteligente",
                    ["puppet_mode"] = "Modo Títere",
                    ["settings"] = "Configuración",
                    ["start_docker"] = "Iniciar Docker",
                    ["documentation"] = "Documentación",
                    ["games"] = "Juegos",

                    ["save"] = "Guardar",
                    ["cancel"] = "Cancelar",
                    ["close"] = "Cerrar",
                    ["send"] = "Enviar"
                },

                ["zh"] = new()
                {
                    ["moxie_controller"] = "OpenMoxie 控制器",
                    ["online"] = "在线",
                    ["offline"] = "离线",
                    ["games"] = "游戏",
                    ["save"] = "保存",
                    ["cancel"] = "取消"
                },

                ["fr"] = new()
                {
                    ["moxie_controller"] = "Contrôleur OpenMoxie",
                    ["online"] = "En ligne",
                    ["offline"] = "Hors ligne",
                    ["games"] = "Jeux",
                    ["save"] = "Sauvegarder",
                    ["cancel"] = "Annuler"
                },

                ["de"] = new()
                {
                    ["moxie_controller"] = "OpenMoxie Steuerung",
                    ["online"] = "Online",
                    ["offline"] = "Offline",
                    ["games"] = "Spiele",
                    ["save"] = "Speichern",
                    ["cancel"] = "Abbrechen"
                },

                ["sv"] = new()
                {
                    ["moxie_controller"] = "OpenMoxie Kontroller",
                    ["online"] = "Online",
                    ["offline"] = "Offline",
                    ["games"] = "Spel",
                    ["save"] = "Spara",
                    ["cancel"] = "Avbryt"
                },

                ["it"] = new()
                {
                    ["moxie_controller"] = "Controller OpenMoxie",
                    ["online"] = "Online",
                    ["offline"] = "Offline",
                    ["games"] = "Giochi",
                    ["save"] = "Salva",
                    ["cancel"] = "Annulla"
                },

                ["ru"] = new()
                {
                    ["moxie_controller"] = "Контроллер OpenMoxie",
                    ["online"] = "Онлайн",
                    ["offline"] = "Офлайн",
                    ["games"] = "Игры",
                    ["save"] = "Сохранить",
                    ["cancel"] = "Отмена"
                },

                ["ja"] = new()
                {
                    ["moxie_controller"] = "OpenMoxie コントローラー",
                    ["online"] = "オンライン",
                    ["offline"] = "オフライン",
                    ["games"] = "ゲーム",
                    ["save"] = "保存",
                    ["cancel"] = "キャンセル"
                }
            };
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class Language
    {
        public string Code { get; set; }
        public string Name { get; set; }
        public string Flag { get; set; }
    }
}
