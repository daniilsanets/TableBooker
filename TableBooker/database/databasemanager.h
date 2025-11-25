#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <QCryptographicHash>

#include "models/AppModels.h"

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static DatabaseManager* instance();

    void initDatabase();

    bool registerUser(const UserData& data);
    UserData authenticateUser(const QString& phone, const QString& password);

    QList<PremisesData> getPremisesForAdmin(int adminId);
    QList<PremisesData> getAllPremises();
    bool createPremises(const PremisesData& data);

    QList<TableData> getTablesForPremises(int premisesId);
    bool saveTableLayout(int premisesId, const QList<TableData>& tables);

    QList<BookingData> getBookingsForTable(int tableId, const QDate& date);
    QList<BookingData> getBookingsForUser(int userId);
    bool createBooking(const BookingData& booking);
    bool cancelBooking(int bookingId, int userId);

private:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();
    void createTables();

    QSqlDatabase m_db;
};

#endif // DATABASEMANAGER_H
