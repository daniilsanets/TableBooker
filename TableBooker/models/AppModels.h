#ifndef APPMODELS_H
#define APPMODELS_H

#include <QString>
#include <QDate>
#include <QDateTime>

struct UserData {
    int id = -1;
    QString username;
    QString displayName;
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
    int width = 80;
    int height = 80;

    // Новые поля
    QString type = "table"; // "table", "wall", "window", "wc", "decoration"
    int rotation = 0;       // Угол поворота в градусах
    QString color = "#81C784"; // Цвет (можно настраивать)

    // shapeType оставляем для формы столов (rect/ellipse),
    // но для стен он будет игнорироваться
    QString shapeType = "rect";
};

struct BookingData {
    int id = -1;
    int tableId = -1;
    int userId = -1;
    QString startTime;
    QString endTime;
    QString tableName;
    QString premisesName;
};

#endif // APPMODELS_H
