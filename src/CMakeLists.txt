cmake_minimum_required(VERSION 3.16)
project(ChronoSlit VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 1. 尋找 Qt6 核心套件
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 2. 定義你的執行檔包含哪些 C++ 檔案
qt_add_executable(chronoslit
    main.cpp
    interval_tree.cpp
    scheduler_controller.h
)

# 3. 註冊 QML 模組 (非常重要，這會把 Main.qml 打包進程式碼)
qt_add_qml_module(chronoslit
    URI ChronoSlitApp
    VERSION 1.0
    QML_FILES Main.qml
)

# 4. 連結 Qt 函式庫
target_link_libraries(chronoslit PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)