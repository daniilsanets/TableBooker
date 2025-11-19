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
            role VARCHAR(20) NOT NULL CHECK(role IN ('user', 'admin'))
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
            name TEXT NOT NULL,
            pos_x INTEGER NOT NULL,
            pos_y INTEGER NOT NULL,
            shape_type TEXT NOT NULL CHECK(shape_type IN ('rect', 'ellipse')),
            width INTEGER NOT NULL CHECK(width > 0),
            height INTEGER NOT NULL CHECK(height > 0),
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
    query.bindValue(":role", data.role);

    if (!query.exec()) {
        qDebug() << "Register error:" << query.lastError().text();
        return false;
    }
    return true;
}

UserData DatabaseManager::authenticateUser(const QString &phone, const QString &password)
{
    QSqlQuery query;
    query.prepare("SELECT id, username, email, phone, nickname, password_hash, role FROM users WHERE phone = :phone");
    query.bindValue(":phone", phone);

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

    query.prepare("INSERT INTO tables (premises_id, name, pos_x, pos_y, shape_type, width, height) "
                  "VALUES (:premId, :name, :x, :y, :shape, :w, :h)");

    for (const TableData& table : tables) {
        query.bindValue(":premId", premisesId);
        query.bindValue(":name", table.name);
        query.bindValue(":x", table.x);
        query.bindValue(":y", table.y);
        query.bindValue(":shape", table.shapeType);
        query.bindValue(":w", table.width);
        query.bindValue(":h", table.height);
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
    query.prepare("SELECT id, premises_id, name, pos_x, pos_y, shape_type, width, height FROM tables WHERE premises_id = :id");
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
            result.append(t);
        }
    }
    return result;
}

bool DatabaseManager::createBooking(const BookingData &booking)
{
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
            result.append(b);
        }
    }
    return result;
}
