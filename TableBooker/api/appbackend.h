#ifndef APPBACKEND_H
#define APPBACKEND_H

#include <QObject>
#include <QVariant>
#include <QList>
#include <QDateTime>
#include <QVariantList>
#include <QVariantMap>
#include "../database/databasemanager.h"

class AppBackend : public QObject
{
    Q_OBJECT
    // Свойства, за которыми следит QML
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY loginStatusChanged)
    Q_PROPERTY(QString currentUserRole READ currentUserRole NOTIFY loginStatusChanged)
    Q_PROPERTY(int currentUserId READ currentUserId NOTIFY loginStatusChanged)

public:
    static AppBackend &instance();

    // Геттеры для свойств
    bool isLoggedIn() const { return m_isLoggedIn; }
    QString currentUserRole() const { return m_currentUserRole; }
    int currentUserId() const { return m_currentUserId; }

    Q_INVOKABLE bool registerUser(const QVariantMap& data);
    Q_INVOKABLE QVariantMap authenticateUser(const QString& phone, const QString& password);

    Q_INVOKABLE QVariantList getPremisesForAdmin(int adminId);
    Q_INVOKABLE QVariantList getAllPremises();
    Q_INVOKABLE bool createPremises(const QVariantMap& data);

    Q_INVOKABLE QVariantList getTablesForPremises(int premisesId);
    Q_INVOKABLE bool saveTableLayout(int premisesId, const QVariantList& tables);

    Q_INVOKABLE QVariantList getBookingsForTable(int tableId, const QDate& date);
    Q_INVOKABLE bool createBooking(const QVariantMap& booking);

signals:
    void loginStatusChanged(); // Сигнал, чтобы QML обновил интерфейс

private:
    explicit AppBackend(QObject *parent = nullptr);

    bool m_isLoggedIn = false;
    QString m_currentUserRole = "";
    int m_currentUserId = -1;
};

#endif // APPBACKEND_H
