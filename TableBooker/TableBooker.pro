QT += quick core gui qml sql quickcontrols2

SOURCES += \
        api/appbackend.cpp \
        database/databasemanager.cpp \
        main.cpp

RESOURCES += qml.qrc \
    qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    api/appbackend.h \
    database/databasemanager.h \
    models/AppModels.h

DISTFILES += \
    main.qml \
    ui/AboutPage.qml \
    ui/LoginScreen.qml \
    ui/RegistrationScreen.qml \
    ui/admin/AdminDashboardPage.qml \
    ui/admin/EditableTableItem.qml \
    ui/admin/HallEditorPage.qml \
    ui/user/BookingHallPage.qml \
    ui/user/BookingPopup.qml \
    ui/user/UserPremisesListPage.qml
