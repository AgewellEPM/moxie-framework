#include "UsageViewModel.h"
#include <QDebug>
#include <QFile>
#include <QTextStream>
#include <algorithm>

UsageViewModel::UsageViewModel(QObject *parent)
    : QAbstractListModel(parent) {
    loadUsageData();
}

int UsageViewModel::rowCount(const QModelIndex &parent) const {
    Q_UNUSED(parent)
    return m_filteredRecords.size();
}

QVariant UsageViewModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_filteredRecords.size())
        return QVariant();

    const UsageRecord &record = m_filteredRecords[index.row()];

    switch (role) {
        case FeatureRole:
            return record.feature;
        case ModelRole:
            return record.aiModel;
        case TokensRole:
            return record.tokensUsed;
        case CostRole:
            return QString("$%1").arg(record.estimatedCost, 0, 'f', 4);
        case TimestampRole:
            return record.timestamp.toString("MM/dd hh:mm");
        case DurationRole:
            return QString("%1s").arg(record.durationSeconds);
        case ChildNameRole:
            return record.childProfileId; // TODO: Get actual child name
        default:
            return QVariant();
    }
}

QHash<int, QByteArray> UsageViewModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[FeatureRole] = "feature";
    roles[ModelRole] = "model";
    roles[TokensRole] = "tokens";
    roles[CostRole] = "cost";
    roles[TimestampRole] = "timestamp";
    roles[DurationRole] = "duration";
    roles[ChildNameRole] = "childName";
    return roles;
}

double UsageViewModel::todayCost() const {
    double cost = 0.0;
    QDateTime today = QDateTime::currentDateTime();

    for (const auto &record : m_records) {
        if (record.timestamp.date() == today.date()) {
            cost += record.estimatedCost;
        }
    }
    return cost;
}

double UsageViewModel::weekCost() const {
    double cost = 0.0;
    QDateTime weekAgo = QDateTime::currentDateTime().addDays(-7);

    for (const auto &record : m_records) {
        if (record.timestamp >= weekAgo) {
            cost += record.estimatedCost;
        }
    }
    return cost;
}

double UsageViewModel::monthCost() const {
    double cost = 0.0;
    QDateTime monthAgo = QDateTime::currentDateTime().addMonths(-1);

    for (const auto &record : m_records) {
        if (record.timestamp >= monthAgo) {
            cost += record.estimatedCost;
        }
    }
    return cost;
}

int UsageViewModel::totalTokens() const {
    int tokens = 0;
    for (const auto &record : m_records) {
        tokens += record.tokensUsed;
    }
    return tokens;
}

int UsageViewModel::totalSessions() const {
    QSet<QString> sessions;
    for (const auto &record : m_records) {
        sessions.insert(record.sessionId);
    }
    return sessions.size();
}

QString UsageViewModel::mostUsedModel() const {
    QMap<QString, int> modelCounts;
    for (const auto &record : m_records) {
        modelCounts[record.aiModel]++;
    }

    QString mostUsed;
    int maxCount = 0;
    for (auto it = modelCounts.begin(); it != modelCounts.end(); ++it) {
        if (it.value() > maxCount) {
            maxCount = it.value();
            mostUsed = it.key();
        }
    }
    return mostUsed;
}

QString UsageViewModel::mostActiveChild() const {
    QMap<QString, int> childCounts;
    for (const auto &record : m_records) {
        childCounts[record.childProfileId]++;
    }

    QString mostActive;
    int maxCount = 0;
    for (auto it = childCounts.begin(); it != childCounts.end(); ++it) {
        if (it.value() > maxCount) {
            maxCount = it.value();
            mostActive = it.key();
        }
    }
    return mostActive;
}

void UsageViewModel::loadUsageData() {
    beginResetModel();

    // TODO: Load from database
    // For now, create sample data
    for (int i = 0; i < 50; ++i) {
        UsageRecord record;
        record.childProfileId = QString("child_%1").arg(i % 3);
        record.feature = i % 4 == 0 ? "chat" : i % 4 == 1 ? "game" : i % 4 == 2 ? "story" : "learning";
        record.aiModel = i % 3 == 0 ? "gpt-4" : i % 3 == 1 ? "gpt-3.5-turbo" : "claude-3-sonnet";
        record.tokensUsed = 100 + (rand() % 900);
        record.estimatedCost = record.calculateCost(record.tokensUsed, record.aiModel);
        record.timestamp = QDateTime::currentDateTime().addDays(-(rand() % 30));
        record.durationSeconds = 30 + (rand() % 300);
        record.sessionId = QString("session_%1").arg(i / 5);

        m_records.append(record);
    }

    m_filteredRecords = m_records;
    endResetModel();

    emit statsChanged();
}

void UsageViewModel::exportToCSV() {
    QString filePath = "usage_export_" + QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss") + ".csv";
    QFile file(filePath);

    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream stream(&file);

        // Header
        stream << "Date,Time,Child,Feature,Model,Tokens,Cost,Duration\n";

        // Data
        for (const auto &record : m_filteredRecords) {
            stream << record.timestamp.toString("yyyy-MM-dd") << ","
                   << record.timestamp.toString("hh:mm:ss") << ","
                   << record.childProfileId << ","
                   << record.feature << ","
                   << record.aiModel << ","
                   << record.tokensUsed << ","
                   << record.estimatedCost << ","
                   << record.durationSeconds << "\n";
        }

        file.close();
        emit exportCompleted(filePath);
    }
}

void UsageViewModel::clearOldData() {
    QDateTime cutoff = QDateTime::currentDateTime().addMonths(-3);

    beginResetModel();
    m_records.erase(std::remove_if(m_records.begin(), m_records.end(),
        [cutoff](const UsageRecord &record) {
            return record.timestamp < cutoff;
        }), m_records.end());

    applyFilters();
    endResetModel();

    emit statsChanged();
}

void UsageViewModel::recordUsage(const UsageRecord &record) {
    beginInsertRows(QModelIndex(), m_records.size(), m_records.size());
    m_records.append(record);

    // Add to filtered if it passes current filters
    m_filteredRecords.append(record);

    endInsertRows();

    emit statsChanged();
}

void UsageViewModel::filterByChild(const QString &childId) {
    beginResetModel();

    if (childId.isEmpty()) {
        m_filteredRecords = m_records;
    } else {
        m_filteredRecords.clear();
        for (const auto &record : m_records) {
            if (record.childProfileId == childId) {
                m_filteredRecords.append(record);
            }
        }
    }

    endResetModel();
    emit statsChanged();
}

void UsageViewModel::filterByDateRange(const QDateTime &start, const QDateTime &end) {
    beginResetModel();

    m_filteredRecords.clear();
    for (const auto &record : m_records) {
        if (record.timestamp >= start && record.timestamp <= end) {
            m_filteredRecords.append(record);
        }
    }

    endResetModel();
    emit statsChanged();
}

void UsageViewModel::calculateStats() {
    // Stats are calculated on-demand through property getters
}

void UsageViewModel::applyFilters() {
    // Apply any active filters
    m_filteredRecords = m_records;
}