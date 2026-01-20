#pragma once

#include <QString>
#include <QObject>
#include <QMetaType>

class Personality {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(QString description MEMBER description)
    Q_PROPERTY(QString emoji MEMBER emoji)
    Q_PROPERTY(QString systemPrompt MEMBER systemPrompt)
    Q_PROPERTY(double temperature MEMBER temperature)
    Q_PROPERTY(int maxTokens MEMBER maxTokens)

public:
    QString id;
    QString name;
    QString description;
    QString emoji;
    QString systemPrompt;
    double temperature = 0.7;
    int maxTokens = 2000;

    static QList<Personality> getBuiltInPersonalities() {
        return {
            {"friendly", "Friendly", "Warm and welcoming", "😊", "You are a friendly and supportive companion.", 0.7, 2000},
            {"encouraging", "Encouraging", "Motivating and positive", "💪", "You are an encouraging mentor.", 0.8, 2000},
            {"playful", "Playful", "Fun and energetic", "🎉", "You are playful and love games.", 0.9, 2000},
            {"teacher", "Teacher", "Educational and patient", "👨‍🏫", "You are a patient teacher.", 0.6, 2500},
            {"storyteller", "Storyteller", "Creative and imaginative", "📚", "You are a creative storyteller.", 0.9, 3000},
            {"scientist", "Scientist", "Curious and analytical", "🔬", "You are a curious scientist.", 0.6, 2000},
            {"artist", "Artist", "Creative and expressive", "🎨", "You are a creative artist.", 0.8, 2000},
            {"explorer", "Explorer", "Adventurous and brave", "🗺️", "You are an adventurous explorer.", 0.8, 2000},
            {"comedian", "Comedian", "Funny and entertaining", "😂", "You are a funny comedian.", 0.9, 2000},
            {"chef", "Chef", "Culinary expert", "👨‍🍳", "You are a culinary expert.", 0.7, 2000}
        };
    }
};

Q_DECLARE_METATYPE(Personality)
