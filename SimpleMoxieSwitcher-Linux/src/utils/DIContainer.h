#pragma once

#include <QObject>
#include <QMap>
#include <QSharedPointer>
#include <typeinfo>

class DIContainer {
public:
    static DIContainer& instance() {
        static DIContainer instance;
        return instance;
    }

    template<typename T>
    void registerSingleton(T* instance) {
        QString key = typeid(T).name();
        m_singletons[key] = QSharedPointer<QObject>(instance);
    }

    template<typename T>
    T* resolve() {
        QString key = typeid(T).name();
        if (m_singletons.contains(key)) {
            return qobject_cast<T*>(m_singletons[key].data());
        }
        return nullptr;
    }

    static void initialize();

private:
    DIContainer() = default;
    QMap<QString, QSharedPointer<QObject>> m_singletons;
};
