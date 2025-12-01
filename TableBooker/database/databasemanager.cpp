#include "databasemanager.h"

DatabaseManager* DatabaseManager::instance()
{
    static DatabaseManager instance;
    return &instance;
}

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent)
{
}

DatabaseManager::~DatabaseManager()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
}

void DatabaseManager::initDatabase()
{
    m_db = QSqlDatabase::addDatabase("QSQLITE");

    // Определяем путь к файлу БД (разный для Android и PC)
#ifdef Q_OS_ANDROID
    QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(path);
    if (!dir.exists()) dir.mkpath(".");
    QString dbPath = path + "/tablebooker.db";
#else
    QString dbPath = "tablebooker.db";
#endif

    qDebug() << "Database path:" << dbPath;
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qDebug() << "Error: connection with database failed";
        qDebug() << m_db.lastError().text();
    } else {
        qDebug() << "Database: connection ok";

        // Включаем поддержку внешних ключей
        QSqlQuery query;
        query.exec("PRAGMA foreign_keys = ON;");

        createTables();
        createDefaultSuperAdmin();
    }
}

void DatabaseManager::createTables()
{
    QSqlQuery query;

    // 1. Users
    QString usersTable = R"(
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username VARCHAR(255) UNIQUE NOT NULL,
            email VARCHAR(320) NULL UNIQUE,
            phone TEXT NOT NULL UNIQUE,
            nickname VARCHAR(100) NOT NULL,
            password_hash VARCHAR(200) NOT NULL,
            role VARCHAR(20) NOT NULL CHECK(role IN ('user', 'admin', 'superadmin'))
        );
    )";
    if (!query.exec(usersTable)) qDebug() << "Error creating users table:" << query.lastError();

    // 2. Premises
    QString premisesTable = R"(
        CREATE TABLE IF NOT EXISTS premises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            admin_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            bg_image_path TEXT,
            FOREIGN KEY(admin_id) REFERENCES users(id)
        );
    )";
    if (!query.exec(premisesTable)) qDebug() << "Error creating premises table:" << query.lastError();

    // 3. Tables
    QString tablesTable = R"(
        CREATE TABLE IF NOT EXISTS tables (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            premises_id INTEGER NOT NULL,
            name TEXT,
            pos_x INTEGER DEFAULT 0,
            pos_y INTEGER DEFAULT 0,
            width INTEGER DEFAULT 80,
            height INTEGER DEFAULT 80,
            rotation INTEGER DEFAULT 0,
            item_type TEXT DEFAULT 'table',
            shape_type TEXT DEFAULT 'rect',
            color TEXT DEFAULT '#CCCCCC',
            FOREIGN KEY(premises_id) REFERENCES premises(id)
        );
    )";
    if (!query.exec(tablesTable)) qDebug() << "Error creating tables table:" << query.lastError();

    // 4. Bookings
    QString bookingsTable = R"(
        CREATE TABLE IF NOT EXISTS bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT NOT NULL,
            FOREIGN KEY(table_id) REFERENCES tables(id),
            FOREIGN KEY(user_id) REFERENCES users(id)
        );
    )";
    if (!query.exec(bookingsTable)) qDebug() << "Error creating bookings table:" << query.lastError();
}

// --- Реализация регистрации и входа ---

bool DatabaseManager::registerUser(const UserData &data)
{
    QSqlQuery checkQuery;
    checkQuery.prepare("SELECT username, email, phone FROM users "
                       "WHERE username = :u OR email = :e OR phone = :p");
    checkQuery.bindValue(":u", data.username);
    checkQuery.bindValue(":e", data.email);
    checkQuery.bindValue(":p", data.phone);

    if (checkQuery.exec()) {
        if (checkQuery.next()) {
            QString existingUser = checkQuery.value("username").toString();
            QString existingEmail = checkQuery.value("email").toString();
            QString existingPhone = checkQuery.value("phone").toString();

            if (existingUser == data.username) {
                qDebug() << "Registration failed: Username" << data.username << "is already taken.";
            }
            if (existingEmail == data.email) {
                qDebug() << "Registration failed: Email" << data.email << "is already registered.";
            }
            if (existingPhone == data.phone) {
                qDebug() << "Registration failed: Phone" << data.phone << "is already used.";
            }

            return false;
        }
    } else {
        qDebug() << "Check duplicate error:" << checkQuery.lastError().text();
        return false;
    }

    QSqlQuery query;
    QString passwordHash = QString(QCryptographicHash::hash(
                                       data.passwordHash.toUtf8(), QCryptographicHash::Sha256).toHex());

    query.prepare("INSERT INTO users (username, email, phone, nickname, password_hash, role) "
                  "VALUES (:username, :email, :phone, :nickname, :pass, :role)");

    query.bindValue(":username", data.username);
    query.bindValue(":email", data.email);
    query.bindValue(":phone", data.phone);
    query.bindValue(":nickname", data.nickname);
    query.bindValue(":pass", passwordHash);
    query.bindValue(":role", data.role.isEmpty() ? "user" : data.role);

    if (!query.exec()) {
        qDebug() << "Register error:" << query.lastError().text();
        return false;
    }
    return true;
}

UserData DatabaseManager::authenticateUser(const QString &identifier, const QString &password)
{
    QSqlQuery query;
    // Ищем введенный identifier сразу в трех столбцах: phone, email или username
    query.prepare("SELECT id, username, email, phone, nickname, password_hash, role "
                  "FROM users WHERE phone = :id OR email = :id OR username = :id");
    query.bindValue(":id", identifier);

    if (!query.exec() || !query.next()) {
        return UserData();
    }

    QString storedHash = query.value("password_hash").toString();
    QString inputHash = QString(QCryptographicHash::hash(
                                    password.toUtf8(), QCryptographicHash::Sha256).toHex());

    if (storedHash != inputHash) {
        return UserData();
    }

    UserData user;
    user.id = query.value("id").toInt();
    user.username = query.value("username").toString();
    user.displayName = query.value("nickname").toString();
    user.email = query.value("email").toString();
    user.phone = query.value("phone").toString();
    user.nickname = query.value("nickname").toString();
    user.role = query.value("role").toString();
    return user;
}

// --- Реализация помещений ---

bool DatabaseManager::createPremises(const PremisesData &data)
{
    QSqlQuery query;
    query.prepare("INSERT INTO premises (admin_id, name, bg_image_path) VALUES (:adminId, :name, :bgPath)");
    query.bindValue(":adminId", data.adminId);
    query.bindValue(":name", data.name);
    query.bindValue(":bgPath", data.bgImagePath);
    return query.exec();
}

QList<PremisesData> DatabaseManager::getPremisesForAdmin(int adminId)
{
    QList<PremisesData> result;
    QSqlQuery query;
    query.prepare("SELECT id, admin_id, name, bg_image_path FROM premises WHERE admin_id = :id");
    query.bindValue(":id", adminId);

    if (query.exec()) {
        while (query.next()) {
            PremisesData p;
            p.id = query.value("id").toInt();
            p.adminId = query.value("admin_id").toInt();
            p.name = query.value("name").toString();
            p.bgImagePath = query.value("bg_image_path").toString();
            result.append(p);
        }
    }
    return result;
}

QList<PremisesData> DatabaseManager::getAllPremises()
{
    QList<PremisesData> result;
    QSqlQuery query("SELECT id, admin_id, name, bg_image_path FROM premises");
    if (query.exec()) {
        while (query.next()) {
            PremisesData p;
            p.id = query.value("id").toInt();
            p.adminId = query.value("admin_id").toInt();
            p.name = query.value("name").toString();
            p.bgImagePath = query.value("bg_image_path").toString();
            result.append(p);
        }
    }
    return result;
}

// --- Реализация столов ---

bool DatabaseManager::saveTableLayout(int premisesId, const QList<TableData> &tables)
{
    m_db.transaction(); // Начинаем транзакцию

    QSqlQuery query;
    query.prepare("DELETE FROM tables WHERE premises_id = :id");
    query.bindValue(":id", premisesId);
    if (!query.exec()) {
        m_db.rollback();
        return false;
    }

    query.prepare("INSERT INTO tables (premises_id, name, pos_x, pos_y, width, height, rotation, item_type, shape_type, color) "
                  "VALUES (:premId, :name, :x, :y, :w, :h, :rot, :type, :shape, :col)");

    for (const TableData& table : tables) {
        query.bindValue(":premId", premisesId);
        query.bindValue(":name", table.name);
        query.bindValue(":x", table.x);
        query.bindValue(":y", table.y);
        query.bindValue(":w", table.width);
        query.bindValue(":h", table.height);
        query.bindValue(":rot", table.rotation);
        query.bindValue(":type", table.type);
        query.bindValue(":shape", table.shapeType);
        query.bindValue(":col", table.color);
        if (!query.exec()) {
            m_db.rollback();
            return false;
        }
    }
    return m_db.commit();
}

QList<TableData> DatabaseManager::getTablesForPremises(int premisesId)
{
    QList<TableData> result;
    QSqlQuery query;
    query.prepare("SELECT * FROM tables WHERE premises_id = :id");
    query.bindValue(":id", premisesId);
    if (query.exec()) {
        while (query.next()) {
            TableData t;
            t.id = query.value("id").toInt();
            t.premisesId = query.value("premises_id").toInt();
            t.name = query.value("name").toString();
            t.x = query.value("pos_x").toInt();
            t.y = query.value("pos_y").toInt();
            t.shapeType = query.value("shape_type").toString();
            t.width = query.value("width").toInt();
            t.height = query.value("height").toInt();
            t.rotation = query.value("rotation").toInt();
            t.type = query.value("item_type").toString();
            t.color = query.value("color").toString();
            result.append(t);
        }
    }
    return result;
}

bool DatabaseManager::createBooking(const BookingData &booking)
{
    QSqlQuery checkQuery;
    checkQuery.prepare("SELECT COUNT(*) FROM bookings WHERE table_id = :tid AND "
                       "started_at < :newEnd AND ended_at > :newStart");

    checkQuery.bindValue(":tid", booking.tableId);
    checkQuery.bindValue(":newStart", booking.startTime);
    checkQuery.bindValue(":newEnd", booking.endTime);

    if (!checkQuery.exec()) {
        qDebug() << "Check booking error:" << checkQuery.lastError().text();
        return false;
    }

    if (checkQuery.next() && checkQuery.value(0).toInt() > 0) {
        qDebug() << "Booking failed: Time slot is already taken!";
        return false;
    }

    QSqlQuery query;
    query.prepare("INSERT INTO bookings (table_id, user_id, started_at, ended_at) VALUES (:tid, :uid, :start, :end)");
    query.bindValue(":tid", booking.tableId);
    query.bindValue(":uid", booking.userId);
    query.bindValue(":start", booking.startTime);
    query.bindValue(":end", booking.endTime);
    return query.exec();
}

QList<BookingData> DatabaseManager::getBookingsForTable(int tableId, const QDate &date)
{
    QList<BookingData> result;
    QSqlQuery query;
    QString dateStr = date.toString("yyyy-MM-dd");
    query.prepare("SELECT id, table_id, user_id, started_at, ended_at FROM bookings WHERE table_id = :tid AND started_at LIKE :datePattern");
    query.bindValue(":tid", tableId);
    query.bindValue(":datePattern", dateStr + "%");

    if (query.exec()) {
        while (query.next()) {
            BookingData b;
            b.id = query.value("id").toInt();
            b.tableId = query.value("table_id").toInt();
            b.userId = query.value("user_id").toInt();
            b.startTime = query.value("started_at").toString();
            b.endTime = query.value("ended_at").toString();
            b.tableName = QString();
            b.premisesName = QString();
            result.append(b);
        }
    }
    return result;
}

QList<BookingData> DatabaseManager::getBookingsForUser(int userId)
{
    QList<BookingData> result;
    QSqlQuery query;
    query.prepare("SELECT b.id, b.table_id, b.user_id, b.started_at, b.ended_at, "
                  "t.name AS table_name, p.name AS premises_name "
                  "FROM bookings b "
                  "JOIN tables t ON b.table_id = t.id "
                  "JOIN premises p ON t.premises_id = p.id "
                  "WHERE b.user_id = :uid "
                  "ORDER BY b.started_at DESC");
    query.bindValue(":uid", userId);

    if (query.exec()) {
        while (query.next()) {
            BookingData b;
            b.id = query.value("id").toInt();
            b.tableId = query.value("table_id").toInt();
            b.userId = query.value("user_id").toInt();
            b.startTime = query.value("started_at").toString();
            b.endTime = query.value("ended_at").toString();
            b.tableName = query.value("table_name").toString();
            b.premisesName = query.value("premises_name").toString();
            result.append(b);
        }
    }
    return result;
}

bool DatabaseManager::cancelBooking(int bookingId, int userId)
{
    QSqlQuery query;
    query.prepare("DELETE FROM bookings WHERE id = :id AND user_id = :uid");
    query.bindValue(":id", bookingId);
    query.bindValue(":uid", userId);
    return query.exec();
}

void DatabaseManager::createDefaultSuperAdmin()
{
    // Проверяем, есть ли уже админ
    QSqlQuery check;
    check.prepare("SELECT id FROM users WHERE role = 'superadmin'");
    if (check.exec() && check.next()) return; // Уже есть, выходим

    // Если нет - создаем
    UserData admin;
    admin.username = "admin";
    admin.passwordHash = "admin123"; // Пароль по умолчанию
    admin.email = "admin@tablebooker.com";
    admin.phone = "000000000";
    admin.nickname = "Super Admin";
    admin.role = "superadmin";

    // Используем существующую функцию регистрации, но нам нужно разрешить роль superadmin
    // (функция registerUser у вас уже есть, но она ставит "user" по умолчанию.
    // Нам нужно чуть-чуть подправить registerUser или написать INSERT вручную тут)

    // Пишем вручную для надежности:
    QSqlQuery query;
    QString hash = QString(QCryptographicHash::hash(admin.passwordHash.toUtf8(), QCryptographicHash::Sha256).toHex());

    query.prepare("INSERT INTO users (username, email, phone, nickname, password_hash, role) "
                  "VALUES (:u, :e, :p, :n, :pass, :role)");
    query.bindValue(":u", admin.username);
    query.bindValue(":e", admin.email);
    query.bindValue(":p", admin.phone);
    query.bindValue(":n", admin.nickname);
    query.bindValue(":pass", hash);
    query.bindValue(":role", "superadmin");

    if(query.exec()) qDebug() << "Super Admin created: login=admin pass=admin123";
    else qDebug() << "Failed to create Super Admin:" << query.lastError().text();
}

QList<UserData> DatabaseManager::getAllUsers()
{
    QList<UserData> list;
    QSqlQuery query("SELECT id, username, nickname, role, phone FROM users ORDER BY id");
    while (query.next()) {
        UserData u;
        u.id = query.value("id").toInt();
        u.username = query.value("username").toString();
        u.nickname = query.value("nickname").toString();
        u.role = query.value("role").toString();
        u.phone = query.value("phone").toString();
        list.append(u);
    }
    return list;
}

bool DatabaseManager::updateUserRole(int userId, const QString &newRole)
{
    QSqlQuery query;
    query.prepare("UPDATE users SET role = :r WHERE id = :id");
    query.bindValue(":r", newRole);
    query.bindValue(":id", userId);
    return query.exec();
}
