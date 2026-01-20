#pragma once

#include <QObject>
#include "../models/Games.h"

class GamesMenuViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(int totalGamesPlayed READ totalGamesPlayed NOTIFY statsChanged)
    Q_PROPERTY(int totalPoints READ totalPoints NOTIFY statsChanged)
    Q_PROPERTY(int bestScore READ bestScore NOTIFY statsChanged)
    Q_PROPERTY(double averageAccuracy READ averageAccuracy NOTIFY statsChanged)

public:
    explicit GamesMenuViewModel(QObject *parent = nullptr);

    int totalGamesPlayed() const { return m_stats.totalGamesPlayed; }
    int totalPoints() const { return m_stats.totalPoints; }
    int bestScore() const { return m_stats.bestScore; }
    double averageAccuracy() const { return m_stats.averageAccuracy; }

    Q_INVOKABLE void loadStats();
    Q_INVOKABLE void startGame(const QString& gameType);

signals:
    void statsChanged();
    void gameStarted(const QString& gameType);

private:
    GameStats m_stats;
};
