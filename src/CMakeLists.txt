cmake_minimum_required(VERSION 3.16)
project(ChronoSlit VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


qt_add_executable(chronoslit
    main.cpp
    interval_tree.cpp
    scheduler_controller.h
    logo.icns
)


set_target_properties(chronoslit PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_ICON_FILE logo.icns
)


qt_add_qml_module(chronoslit
    URI ChronoSlitApp
    VERSION 1.0
    QML_FILES Main.qml
)


target_link_libraries(chronoslit PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)


add_executable(chronoslit_benchmark
    main_benchmark.cpp
    interval_tree.cpp  
)

target_link_libraries(chronoslit_benchmark PRIVATE
    Qt6::Core
)