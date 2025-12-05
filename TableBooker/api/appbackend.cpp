#include "appbackend.h"

AppBackend &AppBackend::instance()
{
    static AppBackend instance;
    return instance;
}

AppBackend::AppBackend(QObject *parent) : QObject(parent)
{
    // При старте можно проверить, есть ли сохраненная сессия (пока пропустим)
}

// --- Пользователи ---

bool AppBackend::registerUser(const QVariantMap &data)
{
    UserData user;
    // 1. Распаковываем данные из QML (JSON) в C++ структуру
    user.username = data["username"].toString();
    user.passwordHash = data["password"].toString(); // Тут пока сырой пароль, хешируем в DatabaseManager
    user.email = data["email"].toString();
    user.phone = data["phone"].toString();
    user.nickname = data["nickname"].toString();
    user.role = "user"; // По умолчанию регистрируем обычных юзеров

    // 2. Вызываем базу
    return DatabaseManager::instance()->registerUser(user);
}

QVariantMap AppBackend::authenticateUser(const QString &phone, const QString &password)
{
    UserData user = DatabaseManager::instance()->authenticateUser(phone, password);

    if (user.isValid()) {
        // Запоминаем состояние внутри приложения
        m_isLoggedIn = true;
        m_currentUserId = user.id;
        m_currentUserRole = user.role;
        m_currentUserName = user.displayName.isEmpty() ? user.username : user.displayName;

        // Уведомляем QML, что свойства изменились
        emit loginStatusChanged();

        // Возвращаем данные юзера обратно в QML
        QVariantMap map;
        map["id"] = user.id;
        map["username"] = user.username;
        map["role"] = user.role;
        map["username"] = user.username;
        map["nickname"] = user.nickname;
        return map;
    }

    return QVariantMap(); // Пустой объект, если вход не удался
}

// --- Помещения ---

QVariantList AppBackend::getPremisesForAdmin(int adminId)
{
    // Получаем C++ список
    QList<PremisesData> list = DatabaseManager::instance()->getPremisesForAdmin(adminId);
    QVariantList result;

    // Перекладываем в QVariantList для QML
    for (const PremisesData &p : list) {
        QVariantMap map;
        map["id"] = p.id;
        map["name"] = p.name;
        map["bgImagePath"] = p.bgImagePath;
        result.append(map);
    }
    return result;
}

QVariantList AppBackend::getAllPremises()
{
    QList<PremisesData> list = DatabaseManager::instance()->getAllPremises();
    QVariantList result;
    for (const PremisesData &p : list) {
        QVariantMap map;
        map["id"] = p.id;
        map["name"] = p.name;
        map["bgImagePath"] = p.bgImagePath;
        result.append(map);
    }
    return result;
}

bool AppBackend::createPremises(const QVariantMap &data)
{
    PremisesData p;
    p.adminId = m_currentUserId; // Берем ID текущего админа
    p.name = data["name"].toString();
    p.bgImagePath = data["bgImagePath"].toString();
    return DatabaseManager::instance()->createPremises(p);
}

// --- Столы ---

QVariantList AppBackend::getTablesForPremises(int premisesId)
{
    QList<TableData> list = DatabaseManager::instance()->getTablesForPremises(premisesId);
    QVariantList result;
    for (const TableData &t : list) {
        QVariantMap map;
        map["id"] = t.id;
        map["name"] = t.name;
        map["x"] = t.x;
        map["y"] = t.y;
        map["width"] = t.width;
        map["height"] = t.height;
        map["shapeType"] = t.shapeType;
        map["type"] = t.type;
        map["rotation"] = t.rotation;
        map["color"] = t.color;
        result.append(map);
    }
    return result;
}

bool AppBackend::saveTableLayout(int premisesId, const QVariantList &tables)
{
    QList<TableData> list;

    for (const QVariant &v : tables) {
        QVariantMap map = v.toMap();
        TableData t;
        t.id = map.contains("id") ? map["id"].toInt() : -1;

        t.name = map["name"].toString();
        t.x = map["x"].toInt();
        t.y = map["y"].toInt();
        t.width = map["width"].toInt();
        t.height = map["height"].toInt();
        t.shapeType = map["shapeType"].toString();
        t.type = map["type"].toString();
        t.rotation = map["rotation"].toInt();
        t.color = map["color"].toString();

        list.append(t);
    }

    return DatabaseManager::instance()->saveTableLayout(premisesId, list);
}

// --- Бронирования ---

QVariantList AppBackend::getBookingsForTable(int tableId, const QDate &date)
{
    QList<BookingData> list = DatabaseManager::instance()->getBookingsForTable(tableId, date);
    QVariantList result;
    for (const BookingData &b : list) {
        QVariantMap map;
        map["id"] = b.id;
        map["userId"] = b.userId;
        map["startTime"] = b.startTime;
        map["endTime"] = b.endTime;
        map["tableName"] = b.tableName;
        map["premisesName"] = b.premisesName;
        result.append(map);
    }
    return result;
}

bool AppBackend::createBooking(const QVariantMap &booking)
{
    BookingData b;
    b.tableId = booking["tableId"].toInt();
    b.userId = m_currentUserId; // Бронирует текущий юзер
    b.startTime = booking["startTime"].toString();
    b.endTime = booking["endTime"].toString();

    return DatabaseManager::instance()->createBooking(b);
}

QVariantList AppBackend::getUserBookings()
{
    QVariantList result;
    if (m_currentUserId < 0)
        return result;

    QList<BookingData> list = DatabaseManager::instance()->getBookingsForUser(m_currentUserId);
    for (const BookingData &b : list) {
        QVariantMap map;
        map["id"] = b.id;
        map["tableId"] = b.tableId;
        map["startTime"] = b.startTime;
        map["endTime"] = b.endTime;
        map["tableName"] = b.tableName;
        map["premisesName"] = b.premisesName;
        result.append(map);
    }
    return result;
}

bool AppBackend::cancelBooking(int bookingId)
{
    if (m_currentUserId < 0)
        return false;
    return DatabaseManager::instance()->cancelBooking(bookingId, m_currentUserId);
}

void AppBackend::logout()
{
    m_isLoggedIn = false;
    m_currentUserId = -1;
    m_currentUserRole.clear();
    m_currentUserName.clear();
    emit loginStatusChanged();
}

QVariantList AppBackend::getAllUsers()
{
    // Только супер-админ может смотреть этот список!
    if (m_currentUserRole != "superadmin") return {};

    QList<UserData> users = DatabaseManager::instance()->getAllUsers();
    QVariantList result;
    for (const auto& u : users) {
        // Себя в списке не показываем, чтобы случайно не удалить права
        if (u.id == m_currentUserId) continue;

        QVariantMap map;
        map["id"] = u.id;
        map["username"] = u.username; // Логин
        map["nickname"] = u.nickname; // Имя
        map["role"] = u.role;
        map["phone"] = u.phone;
        result.append(map);
    }
    return result;
}

bool AppBackend::changeUserRole(int userId, bool makeAdmin)
{
    if (m_currentUserRole != "superadmin") return false;

    QString newRole = makeAdmin ? "admin" : "user";
    return DatabaseManager::instance()->updateUserRole(userId, newRole);
}

bool AppBackend::deletePremises(int id)
{
    return DatabaseManager::instance()->deletePremises(id);
}
