#include "GamesMenuViewModel.h"
#include <QDebug>

GamesMenuViewModel::GamesMenuViewModel(QObject *parent)
    : QObject(parent) {
}

void GamesMenuViewModel::loadStats() {
    // TODO: Load from database/repository
    // For now, sample data
    m_stats.totalGamesPlayed = 15;
    m_stats.totalPoints = 1250;
    m_stats.bestScore = 950;
    m_stats.averageAccuracy = 0.85;

    emit statsChanged();
}

void GamesMenuViewModel::startGame(const QString& gameType) {
    qDebug() << "Starting game:" << gameType;
    emit gameStarted(gameType);
}
