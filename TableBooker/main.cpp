#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include "database/databasemanager.h"
#include "api/appbackend.h"

int main(int argc, char *argv[])
{

    QQuickStyle::setStyle("Basic");

    QGuiApplication app(argc, argv);
    // 1. Инициализируем базу
    DatabaseManager::instance()->initDatabase();

    // 2. РЕГИСТРИРУЕМ НАШ БЭКЕНД (ЭТО ВАЖНО!)
    // Мы говорим: "В пакете com.tablebooker.api версии 1.0 есть объект BackendApi.
    // Бери его из AppBackend::instance()"
    qmlRegisterSingletonInstance("com.tablebooker.api", 1, 0, "BackendApi", &AppBackend::instance());

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/TableBooker/main.qml")); // Проверь, чтобы путь совпадал с твоим проектом

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
