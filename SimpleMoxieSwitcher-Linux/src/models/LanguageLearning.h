#pragma once
#include <QString>
#include <QDateTime>
#include <QList>
#include <QJsonObject>
#include <QMetaType>

enum class LanguageLevel {
    Beginner,
    Elementary,
    Intermediate,
    Advanced,
    Native
};

enum class LanguageSkill {
    Vocabulary,
    Grammar,
    Pronunciation,
    Conversation,
    Reading,
    Writing
};

struct VocabularyItem {
    QString word;
    QString translation;
    QString pronunciation;
    QString context;
    int timesStudied = 0;
    int correctCount = 0;
    QDateTime lastReviewed;
    double masteryLevel = 0.0; // 0-1

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["word"] = word;
        obj["translation"] = translation;
        obj["pronunciation"] = pronunciation;
        obj["timesStudied"] = timesStudied;
        obj["correctCount"] = correctCount;
        obj["masteryLevel"] = masteryLevel;
        return obj;
    }
};

class LanguageLearning {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString childProfileId MEMBER childProfileId)
    Q_PROPERTY(QString targetLanguage MEMBER targetLanguage)
    Q_PROPERTY(QString nativeLanguage MEMBER nativeLanguage)
    Q_PROPERTY(LanguageLevel level READ getLevel WRITE setLevel)
    Q_PROPERTY(int totalWordsLearned READ totalWordsLearned)
    Q_PROPERTY(int streak MEMBER streak)
    Q_PROPERTY(QDateTime lastPractice MEMBER lastPractice)

public:
    QString id;
    QString childProfileId;
    QString targetLanguage;
    QString nativeLanguage;
    QList<VocabularyItem> vocabulary;
    int streak = 0;
    QDateTime lastPractice;
    int totalMinutesStudied = 0;
    QList<LanguageSkill> focusAreas;
    double overallProgress = 0.0;

private:
    LanguageLevel m_level = LanguageLevel::Beginner;

public:
    LanguageLearning() = default;

    LanguageLevel getLevel() const { return m_level; }
    void setLevel(LanguageLevel level) { m_level = level; }

    int totalWordsLearned() const {
        int count = 0;
        for (const auto& item : vocabulary) {
            if (item.masteryLevel >= 0.7) count++;
        }
        return count;
    }

    void addVocabulary(const VocabularyItem& item) {
        vocabulary.append(item);
    }

    void updateStreak() {
        if (lastPractice.daysTo(QDateTime::currentDateTime()) <= 1) {
            streak++;
        } else {
            streak = 1;
        }
        lastPractice = QDateTime::currentDateTime();
    }

    QString levelToString() const {
        switch(m_level) {
            case LanguageLevel::Beginner: return "Beginner";
            case LanguageLevel::Elementary: return "Elementary";
            case LanguageLevel::Intermediate: return "Intermediate";
            case LanguageLevel::Advanced: return "Advanced";
            case LanguageLevel::Native: return "Native";
            default: return "Unknown";
        }
    }
};

Q_DECLARE_METATYPE(LanguageLearning)
Q_DECLARE_METATYPE(VocabularyItem)