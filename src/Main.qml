import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Window {
    id: root
    width: 1280
    height: 800
    visible: true
    title: "ChronoSlit | Professional Kernel"
    
    //  1. 主題顏色與字體變數
    property color themeBg: "#FFFFFF"
    property color sidebarBg: "#FAFAFA"
    color: themeBg

    property string mainFont: "Charter, Baskerville, Georgia, 'Times New Roman', serif"
    property string monoFont: "Menlo, Monaco, monospace"

    //  2. 事件資料庫與通訊
    ListModel {
        id: eventModel
    }

    Connections {
        target: backend
        function onEventAdded(title, startMin, duration, dayIndex) {
            eventModel.append({
                "title": title,
                "startMin": startMin,
                "duration": duration,
                "dayIndex": dayIndex
            });
            console.log("事件已存入模型: " + title);
        }
    }

    Row {
        anchors.fill: parent

        // --- 左側工具列 (Sidebar) ---
        Rectangle {
            id: sidebar
            width: 60
            height: parent.height
            color: root.sidebarBg
            border.color: Qt.darker(root.sidebarBg, 1.05)
            
            ColumnLayout {
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 25

                Rectangle {
                    width: 40; height: 40; radius: 8; color: "transparent"
                    Layout.alignment: Qt.AlignHCenter
                    Text { text: "📅"; anchors.centerIn: parent; font.pixelSize: 20 }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.darker(root.sidebarBg, 1.05)
                        onExited: parent.color = "transparent"
                    }
                }

                Rectangle {
                    id: colorButton
                    width: 40; height: 40; radius: 8; color: "transparent"
                    Layout.alignment: Qt.AlignHCenter
                    Row {
                        anchors.centerIn: parent; spacing: 2
                        Rectangle { width: 6; height: 6; radius: 3; color: "#FF5F56" }
                        Rectangle { width: 6; height: 6; radius: 3; color: "#FFBD2E" }
                        Rectangle { width: 6; height: 6; radius: 3; color: "#27C93F" }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.darker(root.sidebarBg, 1.05)
                        onExited: parent.color = "transparent"
                        onClicked: {
                            arcColorPicker.x = sidebar.width + 10
                            arcColorPicker.y = colorButton.y
                            arcColorPicker.open()
                        }
                    }
                }
            }
        }

        // --- 右側主區域 (畫布 + 終端機) ---
        Column {
            width: parent.width - sidebar.width
            height: parent.height

            Flickable {
                id: mainScrollArea
                width: parent.width
                height: parent.height * 0.9
                contentWidth: width
                contentHeight: 1440 
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: canvasLayout
                    width: mainScrollArea.width
                    height: mainScrollArea.contentHeight

                    // [左側時間軸]
                    Rectangle {
                        width: 60; height: parent.height; color: "transparent"
                        border.color: Qt.darker(root.themeBg, 1.05)
                        Column {
                            anchors.fill: parent
                            Repeater {
                                model: 24
                                Item {
                                    width: 60; height: 60
                                    Text {
                                        text: modelData + ":00"
                                        anchors.centerIn: parent
                                        font.pixelSize: 12
                                        color: "#888"
                                        font.family: root.mainFont
                                        font.italic: true 
                                    }
                                    Rectangle {
                                        width: 15; height: 1
                                        color: Qt.darker(root.themeBg, 1.08)
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                    }
                                }
                            }
                        }
                    }

                    // [中央七天橫向佈局]
                    Row {
                        width: canvasLayout.width - 60
                        height: parent.height

                        Repeater {
                            model: [
                                { day: "Mon", date: "05/04" },
                                { day: "Tue", date: "05/05" },
                                { day: "Wed", date: "05/06" },
                                { day: "Thu", date: "05/07" },
                                { day: "Fri", date: "05/08" },
                                { day: "Sat", date: "05/09" },
                                { day: "Sun", date: "05/10" }
                            ]
                            
                            Rectangle {
                                id: dayColumn
                                property int dayIndex: index // 💡 記住這是星期幾
                                width: (canvasLayout.width - 60) / 7
                                height: parent.height
                                color: "transparent"
                                border.color: Qt.darker(root.themeBg, 1.03)

                                // 星期與日期標題
                                Column {
                                    anchors.top: parent.top
                                    anchors.topMargin: 15
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    z: 2 // 確保標題在事件方塊上方
                                    spacing: 4
                                    Text {
                                        text: modelData.day
                                        font.family: root.mainFont; font.pixelSize: 16; color: "#333"; font.weight: Font.Bold
                                    }
                                    Text {
                                        text: modelData.date
                                        font.family: root.mainFont; font.pixelSize: 13; color: "#777"; font.italic: true
                                    }
                                }

                                //  關鍵：動態繪製事件方塊
                                Repeater {
                                    model: eventModel
                                    delegate: Rectangle {
                                        // 僅在正確的日期顯示
                                        visible: model.dayIndex === dayColumn.dayIndex
                                        
                                        x: 4
                                        y: model.startMin // 1分鐘 = 1像素
                                        width: dayColumn.width - 8
                                        height: model.duration
                                        
                                        radius: 6
                                        color: Qt.alpha("#3182CE", 0.1) // 柔和的 Arc 風格藍
                                        border.color: "#3182CE"
                                        border.width: 1

                                        Text {
                                            text: model.title
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            font.family: root.mainFont
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            color: "#2C5282"
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }
            }

            // [下半部終端機]
            Rectangle {
                width: parent.width; height: parent.height * 0.1; color: "#0D0D0D" 
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 15; spacing: 5
                    Text {
                        text: "FORMAT: YYYY/M/D HH:MM-HH:MM #Title -p policy -t tag"
                        color: "#555"; font.family: root.monoFont; font.pixelSize: 11; Layout.fillWidth: true
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Text { text: "λ"; color: "#00FFCC"; font.family: root.monoFont; font.pixelSize: 18; font.weight: Font.Bold }
                        TextField {
                            id: commandInput
                            Layout.fillWidth: true; color: "#E0E0E0"; font.family: root.monoFont; font.pixelSize: 16; focus: true
                            placeholderText: "Command entry..."; background: Rectangle { color: "transparent" }
                            onAccepted: {
                                if (text !== "") {
                                    backend.parseCommand(text)
                                    text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 調色盤 Popup
    Popup {
        id: arcColorPicker
        width: 220; height: 140; modal: false; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            radius: 12; color: "#FFFFFF"; border.color: "#E0E0E0"
            layer.enabled: true
            layer.effect: DropShadow { transparentBorder: true; color: "#20000000"; radius: 15; samples: 30; verticalOffset: 4 }
        }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 15; spacing: 10
            Text { text: "Theme Color"; font.family: root.mainFont; font.pixelSize: 14; font.weight: Font.Bold; color: "#333" }
            GridLayout {
                columns: 5; columnSpacing: 10; rowSpacing: 10
                Repeater {
                    model: [
                        { bg: "#FFFFFF", sidebar: "#FAFAFA" },
                        { bg: "#FBF9F6", sidebar: "#F4EFEB" },
                        { bg: "#F2F7F4", sidebar: "#E8F0EA" },
                        { bg: "#F0F5FA", sidebar: "#E5EDF5" },
                        { bg: "#F6F2F9", sidebar: "#ECE5F0" },
                        { bg: "#FFF4F4", sidebar: "#FCE8E8" }
                    ]
                    Rectangle {
                        width: 24; height: 24; radius: 12; color: modelData.sidebar; border.color: "#DDD"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.themeBg = modelData.bg; root.sidebarBg = modelData.sidebar }
                        }
                    }
                }
            }
        }
    }
}