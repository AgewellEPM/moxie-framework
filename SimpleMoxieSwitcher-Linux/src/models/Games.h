#pragma once

#include <QString>
#include <QObject>
#include <QDateTime>
#include <QList>

enum class GameType {
    Trivia,
    SpellingBee,
    MovieLines,
    VideoGames,
    KnowledgeQuest
};

enum class Difficulty {
    Easy,
    Medium,
    Hard
};

struct TriviaQuestion {
    QString question;
    QStringList options;
    int correctAnswer;
    QString category;
    Difficulty difficulty;
    int points;
    int userAnswer = -1;
};

struct SpellingWord {
    QString word;
    QString definition;
    QString audioHint;
    Difficulty difficulty;
    int points;
    QString userSpelling;
    int attempts = 0;
};

struct MovieLineChallenge {
    QString movieLine;
    QString correctMovie;
    QStringList options;
    Difficulty difficulty;
    int points;
    int userAnswer = -1;
};

struct VideoGameChallenge {
    QString clue;
    QString correctGame;
    QString franchise;
    QStringList options;
    Difficulty difficulty;
    int points;
    int userAnswer = -1;
};

struct GameSession {
    QString id;
    GameType gameType;
    QDateTime startTime;
    QDateTime endTime;
    int score = 0;
    int correctAnswers = 0;
    int questionsAnswered = 0;
    bool isCompleted = false;

    double accuracy() const {
        return questionsAnswered > 0 ?
            static_cast<double>(correctAnswers) / questionsAnswered : 0.0;
    }
};

struct GameStats {
    int totalGamesPlayed = 0;
    int totalPoints = 0;
    int bestScore = 0;
    double averageAccuracy = 0.0;
    QMap<QString, int> gamesByType;
    QList<QString> achievements;
};
