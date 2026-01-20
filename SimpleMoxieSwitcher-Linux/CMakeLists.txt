cmake_minimum_required(VERSION 3.20)
project(SimpleMoxieSwitcher VERSION 1.0.0 LANGUAGES CXX)

# C++ Standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Qt
find_package(Qt6 REQUIRED COMPONENTS Core Quick Widgets Charts Network Core5Compat)

# Additional dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(MOSQUITTO REQUIRED libmosquitto)

# Source files
set(SOURCES
    src/main.cpp
    # Models
    src/models/Personality.cpp
    src/models/Games.cpp
    src/models/ChildProfile.cpp
    src/models/Conversation.cpp
    src/models/Memory.cpp
    src/models/LanguageLearning.cpp
    src/models/UsageRecord.cpp
    # ViewModels
    src/viewmodels/GamesMenuViewModel.cpp
    src/viewmodels/ChatViewModel.cpp
    src/viewmodels/ControlsViewModel.cpp
    src/viewmodels/UsageViewModel.cpp
    # Services
    src/services/MQTTService.cpp
    src/services/AIProviderService.cpp
    src/services/DockerService.cpp
    src/services/StorageService.cpp
    # Utils
    src/utils/DIContainer.cpp
)

# Headers
set(HEADERS
    # Models
    src/models/Personality.h
    src/models/Games.h
    src/models/ChildProfile.h
    src/models/Conversation.h
    src/models/Memory.h
    src/models/LanguageLearning.h
    src/models/UsageRecord.h
    # ViewModels
    src/viewmodels/GamesMenuViewModel.h
    src/viewmodels/ChatViewModel.h
    src/viewmodels/ControlsViewModel.h
    src/viewmodels/UsageViewModel.h
    # Services
    src/services/MQTTService.h
    src/services/AIProviderService.h
    src/services/DockerService.h
    src/services/StorageService.h
    # Utils
    src/utils/DIContainer.h
)

# QML resources
qt_add_resources(QML_RESOURCES resources/qml.qrc)

# Executable
add_executable(SimpleMoxieSwitcher
    ${SOURCES}
    ${HEADERS}
    ${QML_RESOURCES}
)

target_link_libraries(SimpleMoxieSwitcher
    Qt6::Core
    Qt6::Quick
    Qt6::Widgets
    Qt6::Charts
    Qt6::Network
    Qt6::Core5Compat
    ${MOSQUITTO_LIBRARIES}
)

target_include_directories(SimpleMoxieSwitcher PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${MOSQUITTO_INCLUDE_DIRS}
)

# Installation
install(TARGETS SimpleMoxieSwitcher
    RUNTIME DESTINATION bin
)

install(FILES resources/SimpleMoxieSwitcher.desktop
    DESTINATION share/applications
)

install(FILES resources/icons/SimpleMoxieSwitcher.svg
    DESTINATION share/icons/hicolor/scalable/apps
)

# Packaging
set(CPACK_GENERATOR "DEB;RPM;TGZ")
set(CPACK_PACKAGE_NAME "simplemoxieswitcher")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "OpenMoxie Robot Controller for Linux")
set(CPACK_PACKAGE_CONTACT "support@openmoxie.org")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "qt6-base, mosquitto, docker-ce")
set(CPACK_RPM_PACKAGE_REQUIRES "qt6-qtbase, mosquitto, docker-ce")
include(CPack)
