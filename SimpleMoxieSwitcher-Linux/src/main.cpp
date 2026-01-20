#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

#include "viewmodels/GamesMenuViewModel.h"
#include "viewmodels/ChatViewModel.h"
#include "viewmodels/ControlsViewModel.h"
#include "viewmodels/UsageViewModel.h"
#include "services/MQTTService.h"
#include "services/AIProviderService.h"
#include "utils/DIContainer.h"

int main(int argc, char *argv[])
{
    // Set application metadata
    QGuiApplication::setApplicationName("SimpleMoxieSwitcher");
    QGuiApplication::setOrganizationName("OpenMoxie");
    QGuiApplication::setApplicationVersion("1.0.0");
    QGuiApplication::setOrganizationDomain("openmoxie.org");

    QGuiApplication app(argc, argv);

    // Set application icon
    app.setWindowIcon(QIcon(":/icons/SimpleMoxieSwitcher.svg"));

    // Initialize dependency injection container
    DIContainer::initialize();

    // Register QML types
    qmlRegisterType<GamesMenuViewModel>("OpenMoxie.ViewModels", 1, 0, "GamesMenuViewModel");
    qmlRegisterType<ChatViewModel>("OpenMoxie.ViewModels", 1, 0, "ChatViewModel");
    qmlRegisterType<ControlsViewModel>("OpenMoxie.ViewModels", 1, 0, "ControlsViewModel");
    qmlRegisterType<UsageViewModel>("OpenMoxie.ViewModels", 1, 0, "UsageViewModel");

    // Create QML engine
    QQmlApplicationEngine engine;

    // Create and register global view model instances
    auto* gamesMenuVM = new GamesMenuViewModel(&app);
    auto* chatVM = new ChatViewModel(&app);
    auto* controlsVM = new ControlsViewModel(&app);
    auto* usageVM = new UsageViewModel(&app);

    engine.rootContext()->setContextProperty("gamesMenuViewModel", gamesMenuVM);
    engine.rootContext()->setContextProperty("chatViewModel", chatVM);
    engine.rootContext()->setContextProperty("controlsViewModel", controlsVM);
    engine.rootContext()->setContextProperty("usageViewModel", usageVM);

    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
