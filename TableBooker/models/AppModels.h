#ifndef APPMODELS_H
#define APPMODELS_H

#include <QString>
#include <QDate>
#include <QDateTime>

struct UserData {
    int id = -1;
    QString username;
    QString email;
    QString phone;
    QString nickname;
    QString passwordHash;
    QString role;

    bool isValid() const { return id != -1; }
};

struct PremisesData {
    int id = -1;
    int adminId = -1;
    QString name;
    QString bgImagePath;
};

struct TableData {
    int id = -1;
    int premisesId;
    QString name;
    int x = 0;
    int y = 0;
    QString shapeType;
    int width = 100;
    int height = 100;
};

struct BookingData {
    int id = -1;
    int tableId = -1;
    int userId = -1;
    QString startTime;
    QString endTime;
};

#endif // APPMODELS_H
