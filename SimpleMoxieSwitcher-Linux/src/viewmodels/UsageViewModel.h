#pragma once
#include <QObject>
#include <QAbstractListModel>
#include "../models/UsageRecord.h"

class UsageViewModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(double todayCost READ todayCost NOTIFY statsChanged)
    Q_PROPERTY(double weekCost READ weekCost NOTIFY statsChanged)
    Q_PROPERTY(double monthCost READ monthCost NOTIFY statsChanged)
    Q_PROPERTY(int totalTokens READ totalTokens NOTIFY statsChanged)
    Q_PROPERTY(int totalSessions READ totalSessions NOTIFY statsChanged)
    Q_PROPERTY(QString mostUsedModel READ mostUsedModel NOTIFY statsChanged)
    Q_PROPERTY(QString mostActiveChild READ mostActiveChild NOTIFY statsChanged)

public:
    enum UsageRoles {
        FeatureRole = Qt::UserRole + 1,
        ModelRole,
        TokensRole,
        CostRole,
        TimestampRole,
        DurationRole,
        ChildNameRole
    };

    explicit UsageViewModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    double todayCost() const;
    double weekCost() const;
    double monthCost() const;
    int totalTokens() const;
    int totalSessions() const;
    QString mostUsedModel() const;
    QString mostActiveChild() const;

public slots:
    void loadUsageData();
    void exportToCSV();
    void clearOldData();
    void recordUsage(const UsageRecord &record);
    void filterByChild(const QString &childId);
    void filterByDateRange(const QDateTime &start, const QDateTime &end);

signals:
    void statsChanged();
    void exportCompleted(const QString &filePath);

private:
    QList<UsageRecord> m_records;
    QList<UsageRecord> m_filteredRecords;

    void calculateStats();
    void applyFilters();
};