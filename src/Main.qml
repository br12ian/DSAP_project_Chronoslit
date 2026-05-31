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
    
    // ── 1. 主題顏色與字體變數 ───────────────────────────────────────────
    property color themeBg: "#FFFFFF"
    property color sidebarBg: "#FAFAFA"
    color: themeBg

    property string mainFont: "Charter, Baskerville, Georgia, 'Times New Roman', serif"
    property string monoFont: "Menlo, Monaco, monospace"

    property bool isMonthView: false
    property string currentRangeLabel: "2026年 5月"
    property int colorUpdateTrigger: 0

    property bool expectJump: false
    property real jumpToY: -1
    property bool triggerNewPops: false

    // 💡 智慧色彩變換引擎
    function getTagColor(tag, alpha) {
        var trigger = root.colorUpdateTrigger
        var baseColorStr = "#A0AEC0"
        for (var i = 0; i < tagModel.count; i++) {
            if (tagModel.get(i).name === tag) {
                baseColorStr = tagModel.get(i).colorCode
                break
            }
        }
        var c = Qt.color(baseColorStr)
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    // ── 3. 事件與標籤資料庫 ──────────────────────────────────────────────
    ListModel { id: eventModel }
    ListModel { id: headerModel } 
    ListModel { id: monthWeekModel } 
    
    ListModel { 
        id: tagModel 
        ListElement { name: "Work"; colorCode: "#3182CE" }
        ListElement { name: "Study"; colorCode: "#D69E2E" }
        ListElement { name: "Gym"; colorCode: "#E53E3E" }
        ListElement { name: "Rest"; colorCode: "#38A169" }
    }

    // ── 4. 核心排版演算法 ────────────────────────────────────────────────
    function computeWeekLayout() {
        if (root.isMonthView) return
        for (var i = 0; i < eventModel.count; i++) {
            eventModel.setProperty(i, "subCol", 0)
            eventModel.setProperty(i, "totalCols", 1)
        }
        for (var day = 0; day < 7; day++) {
            var dayIndices = []
            for (var j = 0; j < eventModel.count; j++) {
                if (eventModel.get(j).dayIndex === day) dayIndices.push(j)
            }
            if (dayIndices.length === 0) continue
            dayIndices.sort(function(a, b) { return eventModel.get(a).startMin - eventModel.get(b).startMin })
            var clusters = []
            var currentCluster = [dayIndices[0]]
            var clusterEnd = eventModel.get(dayIndices[0]).startMin + eventModel.get(dayIndices[0]).duration
            for (var k = 1; k < dayIndices.length; k++) {
                var idx = dayIndices[k]
                var ev = eventModel.get(idx)
                if (ev.startMin < clusterEnd) {
                    currentCluster.push(idx)
                    clusterEnd = Math.max(clusterEnd, ev.startMin + ev.duration)
                } else {
                    clusters.push(currentCluster)
                    currentCluster = [idx]
                    clusterEnd = ev.startMin + ev.duration
                }
            }
            clusters.push(currentCluster)
            for (var g = 0; g < clusters.length; g++) {
                var cluster = clusters[g]
                var columns = [] 
                for (var cIdx = 0; cIdx < cluster.length; cIdx++) {
                    var c_idx = cluster[cIdx]
                    var c_ev = eventModel.get(c_idx)
                    var start = c_ev.startMin
                    var end = start + c_ev.duration
                    var placed = false
                    for (var c = 0; c < columns.length; c++) {
                        if (start >= columns[c]) {
                            columns[c] = end
                            eventModel.setProperty(c_idx, "subCol", c)
                            placed = true
                            break
                        }
                    }
                    if (!placed) {
                        eventModel.setProperty(c_idx, "subCol", columns.length)
                        columns.push(end)
                    }
                }
                for (var setIdx = 0; setIdx < cluster.length; setIdx++) {
                    eventModel.setProperty(cluster[setIdx], "totalCols", columns.length)
                }
            }
        }
    }

    function computeMonthLayout() {
        if (!root.isMonthView) return
        var dayCounts = new Array(42).fill(0)
        for (var i = 0; i < eventModel.count; i++) {
            var dIdx = eventModel.get(i).dayIndex
            if (dIdx >= 0 && dIdx < 42) dayCounts[dIdx]++
        }
        for (var w = 0; w < 6; w++) {
            var maxEventsInThisWeek = 0
            for (var d = 0; d < 7; d++) {
                maxEventsInThisWeek = Math.max(maxEventsInThisWeek, dayCounts[w * 7 + d])
            }
            if (w < monthWeekModel.count) {
                monthWeekModel.setProperty(w, "maxEvents", maxEventsInThisWeek)
            }
        }
    }

    Connections {
        target: backend
        function onEventAdded(id, title, startMin, duration, dayIndex, tag, globalDate) {
            eventModel.append({
                "eventId": id, 
                "title": title,
                "startMin": startMin,
                "duration": duration,
                "dayIndex": dayIndex,
                "tag": tag,
                "globalDate": globalDate,
                "subCol": 0,
                "totalCols": 1,
                "isNew": root.expectJump
            })
            Qt.callLater(root.isMonthView ? root.computeMonthLayout : root.computeWeekLayout)

            if (!root.isMonthView) {
                // startMin 就是該行程在畫布上的 Y 軸絕對座標
                // 減去 100 像素是為了在上方留下一點漂亮的預留空間，不會讓行程死貼著頂端
                autoScrollAnim.to = Math.max(0, startMin - 100)
                autoScrollAnim.start()
            }
        }
        function onCalendarCleared() { eventModel.clear() }
        function onViewChanged(dayLabels, dateLabels, isCurrentMonthList, isTodayList, rangeLabel) {
            headerModel.clear()
            for (var i = 0; i < dateLabels.length; ++i) {
                headerModel.append({ 
                    dayName: dayLabels[i % 7],
                    dateStr: dateLabels[i],
                    isCurMonth: isCurrentMonthList[i],
                    isToday: isTodayList[i]
                })
            }
            root.currentRangeLabel = rangeLabel
            monthWeekModel.clear()
            for (var w = 0; w < 6; w++) { monthWeekModel.append({"maxEvents": 0}) }
            Qt.callLater(root.isMonthView ? root.computeMonthLayout : root.computeWeekLayout)

            if (root.expectJump && root.jumpToY >= 0) {
                var targetY = root.jumpToY - 100 
                var maxLegalY = mainScrollArea.contentHeight - mainScrollArea.height
                autoScrollAnim.to = Math.max(0, Math.min(targetY, maxLegalY))
                autoScrollAnim.start()
                root.expectJump = false
            }
        }

        function onTagAdded(name, colorCode) {
            // 安全防護：檢查是否已經有同名的標籤，避免重複附加
            for (var i = 0; i < tagModel.count; i++) {
                if (tagModel.get(i).name === name) {
                    return
                }
            }
            tagModel.append({ "name": name, "colorCode": colorCode })
            root.colorUpdateTrigger++
        }

        function onTagRemoved(name) {
            for (var i = 0; i < tagModel.count; i++) {
                if (tagModel.get(i).name === name) {
                    tagModel.remove(i)
                    root.colorUpdateTrigger++ // 觸發畫布刷新，讓該標籤的行程變回預設安全灰色
                    break
                }
            }
        }

        function onShowTerminalHint(msg) {
            terminalPrompt.text = msg
            terminalPrompt.color = "#FF007F" // 變成超醒目的電競粉紅字！
            hintResetTimer.start()           // 啟動 5 秒倒數計時
        }
    }

    Component.onCompleted: backend.initView()

    Row {
        anchors.fill: parent

        // ─── 左側工具列 (Sidebar) ─────────────────────────────────────────
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
                    width: 40
                    height: 40
                    radius: 8
                    color: "transparent"
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        text: root.isMonthView ? "📅" : "🗓️"
                        anchors.centerIn: parent
                        font.pixelSize: 20
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.darker(sidebarBg, 1.05)
                        onExited: parent.color = "transparent"
                        onClicked: {
                            root.isMonthView = !root.isMonthView
                            backend.toggleViewMode(root.isMonthView)
                        }
                    }
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: 8
                    color: "transparent"
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        text: "🏷️"
                        anchors.centerIn: parent
                        font.pixelSize: 18
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.darker(sidebarBg, 1.05)
                        onExited: parent.color = "transparent"
                        onClicked: {
                            tagManagerPopup.x = sidebar.width + 10
                            tagManagerPopup.y = parent.y
                            tagManagerPopup.open()
                        }
                    }
                }

                Rectangle {
                    id: colorButton
                    width: 40
                    height: 40
                    radius: 8
                    color: "transparent"
                    Layout.alignment: Qt.AlignHCenter
                    Row {
                        anchors.centerIn: parent
                        spacing: 2
                        Rectangle { width: 6; height: 6; radius: 3; color: "#FF5F56" }
                        Rectangle { width: 6; height: 6; radius: 3; color: "#FFBD2E" }
                        Rectangle { width: 6; height: 6; radius: 3; color: "#27C93F" }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.darker(sidebarBg, 1.05)
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

        // ─── 右側主區域 ───────────────────────────────────────────────────
        Column {
            width: parent.width - sidebar.width
            height: parent.height

            // 1. 上方導覽列
            Rectangle {
                id: navBar
                width: parent.width
                height: 50
                color: root.themeBg 
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 15
                    Text {
                        text: root.currentRangeLabel
                        font.family: root.mainFont
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: "#222"
                    }
                    Item { Layout.fillWidth: true } 
                    Button { text: "<-"; implicitWidth: 40; onClicked: backend.prevRange() }
                    Button { text: "_Today_"; implicitWidth: 100; onClicked: backend.goToToday() } // 串接歸位今天功能
                    Button { text: "->"; implicitWidth: 40; onClicked: backend.nextRange() }
                }
            }

            // 2. 中央雙視圖切換區 (佔比 90% 高度減去導覽列)
            StackLayout {
                width: parent.width
                height: parent.height * 0.9 - navBar.height 
                currentIndex: root.isMonthView ? 1 : 0

                // =================================================================
                // [Index 0: 週曆視圖] (💡 純 Row/Item 絕對幾何版，星期與日期完美釘在頂部)
                // =================================================================
                Item {
                    id: weekViewWrapper

                    // ─── 💡 固定置頂的雙行日期頁首 ───
                    Rectangle {
                        id: fixedWeekHeader
                        width: parent.width
                        height: 55 
                        color: "#FFFFFF"
                        anchors.top: parent.top
                        z: 10 

                        Row {
                            anchors.fill: parent
                            
                            // 左側時間軸對齊墊片 (60 像素)
                            Item {
                                width: 60
                                height: parent.height
                            }

                            // 右側七天置頂橫欄
                            Row {
                                width: parent.width - 60
                                height: parent.height
                                Repeater {
                                    model: 7
                                    Rectangle {
                                        width: parent.width / 7 
                                        height: parent.height
                                        color: (index < headerModel.count && headerModel.get(index).isToday) ? getTagColor("Work", 0.05) : "transparent"

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 3

                                            // 上行：星期幾
                                            Text {
                                                text: index < headerModel.count ? headerModel.get(index).dayName : ""
                                                font.family: root.mainFont
                                                font.pixelSize: 13
                                                font.weight: (index < headerModel.count && headerModel.get(index).isToday) ? Font.Bold : Font.Normal
                                                color: (index < headerModel.count && headerModel.get(index).isToday) ? "#3182CE" : "#4A5568"
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }

                                            // 下行：精準日期數字
                                            Text {
                                                text: index < headerModel.count ? headerModel.get(index).dateStr : ""
                                                font.family: root.mainFont
                                                font.pixelSize: 11
                                                font.weight: (index < headerModel.count && headerModel.get(index).isToday) ? Font.Bold : Font.Normal
                                                color: (index < headerModel.count && headerModel.get(index).isToday) ? "#3182CE" : "#A0AEC0"
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                        }
                                        
                                        // 今日上方點綴藍條
                                        Rectangle {
                                            width: 20; height: 3; radius: 1.5; color: "#3182CE"
                                            visible: index < headerModel.count && headerModel.get(index).isToday
                                            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 隔離細線
                    Rectangle {
                        id: headerDivider
                        width: parent.width
                        height: 1
                        color: "#E2E8F0"
                        anchors.top: fixedWeekHeader.bottom
                    }

                    // 下方行程網格滾動區
                    Flickable {
                        id: mainScrollArea
                        width: parent.width
                        anchors.top: headerDivider.bottom
                        anchors.bottom: parent.bottom
                        contentWidth: width
                        contentHeight: 1440 
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        NumberAnimation {
                            id: autoScrollAnim
                            target: mainScrollArea
                            property: "contentY"
                            duration: 350
                            easing.type: Easing.OutCubic
                            onFinished: {
                                root.triggerNewPops = true
                                resetPopTimer.start()
                            }
                        }

                        Timer {
                            id: resetPopTimer
                            interval: 600
                            onTriggered: {
                                root.triggerNewPops = false
                                for (var i = 0; i < eventModel.count; i++) {
                                    eventModel.setProperty(i, "isNew", false)
                                }
                            }
                        }

                        Row {
                            id: canvasLayout
                            width: mainScrollArea.width
                            height: mainScrollArea.contentHeight

                            // 左側時間軸刻度
                            Rectangle {
                                width: 60
                                height: parent.height
                                color: "transparent"
                                border.color: Qt.darker(root.themeBg, 1.05)
                                Column {
                                    anchors.fill: parent
                                    Repeater {
                                        model: 24
                                        Item {
                                            width: 60
                                            height: 60
                                            Text {
                                                text: modelData + ":00"
                                                anchors.centerIn: parent
                                                font.pixelSize: 12
                                                color: "#888"
                                                font.family: root.mainFont
                                                font.italic: true
                                            }
                                            Rectangle {
                                                width: 15
                                                height: 1
                                                color: Qt.darker(root.themeBg, 1.08)
                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                            }
                                        }
                                    }
                                }
                            }

                            // 右側七天行程繪製區
                            Row {
                                width: canvasLayout.width - 60
                                height: parent.height
                                Repeater {
                                    model: 7
                                    Rectangle {
                                        id: weekDayColumn
                                        property int colIndex: index 
                                        width: (canvasLayout.width - 60) / 7
                                        height: parent.height
                                        color: "transparent"
                                        border.color: Qt.darker(root.themeBg, 1.05)

                                        Repeater {
                                            model: eventModel
                                            delegate: Rectangle {
                                                visible: model.dayIndex === weekDayColumn.colIndex
                                                width: (weekDayColumn.width - 8) / (model.totalCols ? model.totalCols : 1)
                                                x: 4 + (model.subCol ? model.subCol : 0) * width
                                                y: model.startMin
                                                height: model.duration
                                                radius: 6
                                                color: getTagColor(model.tag, 0.15) 
                                                border.color: getTagColor(model.tag, 1.0)
                                                border.width: 1

                                                scale: (model.isNew && !root.triggerNewPops) ? 0 : 1
                                                
                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 350
                                                        easing.type: Easing.OutBack 
                                                    }
                                                }

                                                Text {
                                                    text: model.eventId + " | " + model.title
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    font.family: root.mainFont
                                                    font.pixelSize: 12
                                                    font.weight: Font.Medium
                                                    color: Qt.darker(getTagColor(model.tag, 1.0), 1.2)
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
                }

                // =================================================================
                // [Index 1: 動態月曆視圖]
                // =================================================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.themeBg
                    Column {
                        anchors.fill: parent
                        Row {
                            width: parent.width
                            height: 35
                            Repeater {
                                model: ["週一", "週二", "週三", "週四", "週五", "週六", "週日"]
                                Text { 
                                    width: parent.width / 7
                                    height: 35
                                    text: modelData
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: root.mainFont
                                    font.pixelSize: 13
                                    color: "#777" 
                                }
                            }
                        }

                        Flickable {
                            width: parent.width
                            height: parent.height - 35
                            contentWidth: width
                            contentHeight: monthStack.height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded } 

                            Column {
                                id: monthStack
                                width: parent.width
                                Repeater {
                                    model: monthWeekModel 
                                    Rectangle {
                                        id: weekRowItem
                                        property int weekIdx: index
                                        width: parent.width
                                        height: Math.max(110, 40 + model.maxEvents * 24)
                                        color: "transparent"
                                        
                                        Row {
                                            anchors.fill: parent
                                            Repeater {
                                                model: 7 
                                                Rectangle {
                                                    id: cellRect
                                                    property int globalDayIdx: weekRowItem.weekIdx * 7 + index 
                                                    property var cellData: headerModel.count > globalDayIdx ? headerModel.get(globalDayIdx) : null

                                                    width: weekRowItem.width / 7
                                                    height: weekRowItem.height
                                                    border.color: "#EAEAEA"
                                                    border.width: 1
                                                    color: cellData && cellData.isCurMonth ? "#FFFFFF" : "#FAFAFA" 

                                                    Rectangle {
                                                        anchors.fill: parent
                                                        color: "#000000"
                                                        opacity: cellMouse.containsMouse ? 0.02 : 0.0
                                                    }
                                                    MouseArea { id: cellMouse; anchors.fill: parent; hoverEnabled: true }
                                                    
                                                    Rectangle {
                                                        id: todayBadge
                                                        width: 24
                                                        height: 24
                                                        radius: 12
                                                        color: cellData && cellData.isToday ? "#EA4335" : "transparent" 
                                                        anchors.top: parent.top
                                                        anchors.right: parent.right
                                                        anchors.margins: 4
                                                        Text {
                                                            text: cellData ? cellData.dateStr : ""
                                                            anchors.centerIn: parent
                                                            font.pixelSize: 14
                                                            font.family: root.mainFont
                                                            color: cellData && cellData.isToday ? "white" : (cellData && cellData.isCurMonth ? "#333" : "#AAA")
                                                            font.weight: cellData && cellData.isToday ? Font.Bold : Font.Normal
                                                        }
                                                    }

                                                    Column {
                                                        anchors.top: todayBadge.bottom
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.topMargin: 2
                                                        anchors.leftMargin: 4
                                                        anchors.rightMargin: 4
                                                        spacing: 2
                                                        clip: true

                                                        Repeater {
                                                            model: eventModel
                                                            delegate: Rectangle {
                                                                property bool isThisCell: (model.dayIndex === cellRect.globalDayIdx)
                                                                visible: isThisCell
                                                                width: parent.width
                                                                height: isThisCell ? 22 : 0 
                                                                radius: 4
                                                                color: getTagColor(model.tag, 0.1)
                                                                border.color: getTagColor(model.tag, 0.25) 

                                                                Rectangle {
                                                                    width: 3
                                                                    height: parent.height
                                                                    radius: 3
                                                                    color: getTagColor(model.tag, 1.0)
                                                                }
                                                                Text { 
                                                                    text: model.eventId + " | " + model.title
                                                                    anchors.verticalCenter: parent.verticalCenter
                                                                    anchors.left: parent.left
                                                                    anchors.leftMargin: 8
                                                                    color: "#333333"
                                                                    font.pixelSize: 12
                                                                    font.family: root.mainFont
                                                                    font.weight: Font.Medium
                                                                    elide: Text.ElideRight
                                                                    width: parent.width - 12
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // ─── 💡 3. 終端機命令列 (Terminal Bar) ───
            // 完美復活！佔據最底部的 10% 空間，並套用你之前所有的果凍跳轉攔截標記
            // =================================================================
            Rectangle {
                id: terminalContainer
                width: parent.width
                height: parent.height * 0.1 // 保持原有的 10% 空間比例
                color: '#000000'

                Rectangle {
                    width: parent.width
                    height: 1
                    color: '#5c3535'
                    anchors.top: parent.top
                }

                // 💡 使用 Column 結構，完美垂直分出「上行提示、下行輸入」
                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 20   // 對齊主區域導覽列的左邊距
                    anchors.rightMargin: 20  // 對齊主區域導覽列的右邊距
                    anchors.topMargin: 8     // 內襯上邊距，拉開兩行文字的空間
                    spacing: 4               // 上下兩行之間的精細間距

                    // ── 上行：輸入提示文字 ──
                    Text {
                        id: terminalPrompt
                        text: "Enter schedule (e.g., 明天 14-16 #Study, 2026/4/4 15:00-17:00 #LinearAlgebra -p hard -t study) or control via /find, /rm"
                        font.family: root.mainFont
                        font.pixelSize: 12
                        color: '#8d8d8d' // 現代質感的灰色提示字
                    }

                    // ── 下行：真正的輸入框 ──
                    TextField {
                        id: commandInput
                        width: parent.width
                        height: 28
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.mainFont
                        font.pixelSize: 14
                        placeholderText: "Type a command..."
                        color: '#ffffff' 
                        focus: true
                        
                        background: Rectangle { color: '#000000' }

                        // 保持你原本寫好的送出指令邏輯
                        onAccepted: {
                            if (text !== "") {
                                root.jumpToY = -1
                                root.expectJump = true
                                root.triggerNewPops = false
                                backend.parseCommand(text)
                                text = ""
                            }
                        }

                        // ── 💡 核心黑科技：直接在輸入框內攔截「按住」與「放開」 ──
                        Keys.onPressed: (event) => {
                            if (event.isAutoRepeat) return; // 🛑 關鍵：過濾作業系統的連續按鍵干擾，只抓第一次按下

                            // 同時支援 Mac 的 Command 鍵 (Meta) 與一般的 Control 鍵
                            var isCtrlOrCmd = (event.modifiers & Qt.ControlModifier) || (event.modifiers & Qt.MetaModifier);
                            
                            if (isCtrlOrCmd) {
                                // 1. 按住 T 鍵 ➔ 彈出標籤視窗
                                if (event.key === Qt.Key_T) {
                                    tagManagerPopup.focus = false // 🛑 強制不讓彈出視窗搶走焦點，手指放開才能被偵測到
                                    tagManagerPopup.x = sidebar.width + 10
                                    tagManagerPopup.y = 120
                                    tagManagerPopup.open() 
                                    event.accepted = true // 攔截事件，防止字母 't' 被打進輸入框
                                }
                                // 2. 按住 P 鍵 ➔ 彈出顏色視窗
                                else if (event.key === Qt.Key_P) {
                                    arcColorPicker.focus = false  // 🛑 強制不讓彈出視窗搶走焦點
                                    arcColorPicker.x = sidebar.width + 10
                                    arcColorPicker.y = 180
                                    arcColorPicker.open()
                                    event.accepted = true
                                }
                                // 3. 按左右方向鍵 ➔ 直接切換週曆時間
                                else if (event.key === Qt.Key_Left) {
                                    backend.prevRange()
                                    event.accepted = true
                                }
                                else if (event.key === Qt.Key_Right) {
                                    backend.nextRange()
                                    event.accepted = true
                                }
                            }
                        }

                        Keys.onReleased: (event) => {
                            if (event.isAutoRepeat) return; // 🛑 關鍵：過濾放開時的連擊干擾

                            // 手指一離開 T 鍵、Control 鍵或 Mac 的 Command 鍵，立刻關閉標籤
                            if (event.key === Qt.Key_T || event.key === Qt.Key_Control || event.key === Qt.Key_Meta) {
                                tagManagerPopup.close()
                            }
                            // 手指一離開 P 鍵、Control 鍵或 Mac 的 Command 鍵，立刻關閉顏色
                            if (event.key === Qt.Key_P || event.key === Qt.Key_Control || event.key === Qt.Key_Meta) {
                                arcColorPicker.close()
                            }
                        }
                    }
                }
            }
        }
    }
    // ── 5. 所有彈出視窗 Popups ──────────────────────────────────────────────

    // ── 💡 修正版：唯讀標籤看板 (完全移除 GUI 增刪功能，全權交給 CLI 驅動) ──
    Popup {
        id: tagManagerPopup
        width: 250
        height: 300 // 移除輸入框後高度微調縮小，比例更精緻
        modal: true
        dim: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            radius: 12
            color: "#FFFFFF"
            border.color: "#E0E0E0"
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: "#20000000"
                radius: 15
                samples: 30
                verticalOffset: 4
            }
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12
            
            Text { 
                text: "Category Tags"; 
                font.family: root.mainFont; 
                font.pixelSize: 15; 
                font.weight: Font.Bold; 
                color: "#333" 
            }
            
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: tagListCol.height
                
                ColumnLayout {
                    id: tagListCol
                    width: parent.width
                    spacing: 14
                    
                    Repeater {
                        model: tagModel
                        RowLayout {
                            width: parent.width
                            spacing: 12
                            
                            // 💡 點擊色圈依然可以觸發調色盤修改顏色，高彈性保留！
                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: model.colorCode
                                border.color: Qt.darker(model.colorCode, 1.2)
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { 
                                        tagColorPickerPopup.editingTagIndex = index
                                        tagColorPickerPopup.previewColor = model.colorCode
                                        tagColorPickerPopup.open() 
                                    }
                                }
                            }
                            
                            Text { 
                                text: model.name
                                font.family: root.mainFont
                                font.pixelSize: 14
                                color: "#444"
                                font.weight: Font.Medium
                                Layout.fillWidth: true 
                            }
                            
                            // ── ✕ 刪除按鈕已被徹底封印移除，實現真正唯讀 ──
                        }
                    }
                }
            }
            // ── 底部的輸入框與 + 按鈕已被徹底封印移除，實現真正唯讀 ──
        }
    }

    // B. 頂級 HSV 調色盤 (AoT 預編譯完美合規版)
    Popup {
        id: tagColorPickerPopup

        property int   editingTagIndex: -1
        property color previewColor:    "#3182CE"
        property color originalColor:   "#3182CE"

        property real  hue: 0.56
        property real  sat: 0.76
        property real  val: 1.0  

        readonly property real wheelRadius: 85   

        onHueChanged: _sync()
        onSatChanged: _sync()
        onValChanged: _sync()
        function _sync() { previewColor = Qt.hsva(hue, sat, val, 1.0) }

        onAboutToShow: {
            if (editingTagIndex < 0) return
            var c = Qt.color(tagModel.get(editingTagIndex).colorCode)
            originalColor = c
            previewColor  = c
            hue = (c.hsvHue < 0) ? 0 : c.hsvHue   
            sat = c.hsvSaturation
            val = c.hsvValue
            
            Qt.callLater(function() {
                var angle = hue * 2 * Math.PI
                var dist  = sat * wheelRadius
                wheelCursor.x = (wheelRadius + Math.cos(angle) * dist) - wheelCursor.width  / 2
                wheelCursor.y = (wheelRadius + Math.sin(angle) * dist) - wheelCursor.height / 2
            })
        }

        width: 284
        height: 438
        modal: true
        focus: true
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 20
            color: root.themeBg
            border.color: Qt.rgba(0, 0, 0, 0.06)
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: "#38000000"
                radius: 32
                samples: 64
                verticalOffset: 10
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Pick Color"; font.family: root.mainFont; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 0.4; color: "#1A202C" }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: tagColorPickerPopup.previewColor
                    border.color: Qt.darker(tagColorPickerPopup.previewColor, 1.18)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    layer.enabled: true 
                    layer.effect: DropShadow { 
                        transparentBorder: true 
                        color: Qt.rgba(tagColorPickerPopup.previewColor.r, tagColorPickerPopup.previewColor.g, tagColorPickerPopup.previewColor.b, 0.45) 
                        radius: 6
                        samples: 12
                        verticalOffset: 2
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: tagColorPickerPopup.wheelRadius * 2
                height: tagColorPickerPopup.wheelRadius * 2
                Rectangle {
                    anchors.fill: parent
                    radius: tagColorPickerPopup.wheelRadius
                    clip: true
                    ConicalGradient {
                        anchors.fill: parent
                        angle: 0.0
                        gradient: Gradient {
                            GradientStop { position: 0/12.0; color: Qt.hsva( 0/12.0, 1, 1, 1) }
                            GradientStop { position: 1/12.0; color: Qt.hsva( 1/12.0, 1, 1, 1) }
                            GradientStop { position: 2/12.0; color: Qt.hsva( 2/12.0, 1, 1, 1) }
                            GradientStop { position: 3/12.0; color: Qt.hsva( 3/12.0, 1, 1, 1) }
                            GradientStop { position: 4/12.0; color: Qt.hsva( 4/12.0, 1, 1, 1) }
                            GradientStop { position: 5/12.0; color: Qt.hsva( 5/12.0, 1, 1, 1) }
                            GradientStop { position: 6/12.0; color: Qt.hsva( 6/12.0, 1, 1, 1) }
                            GradientStop { position: 7/12.0; color: Qt.hsva( 7/12.0, 1, 1, 1) }
                            GradientStop { position: 8/12.0; color: Qt.hsva( 8/12.0, 1, 1, 1) }
                            GradientStop { position: 9/12.0; color: Qt.hsva( 9/12.0, 1, 1, 1) }
                            GradientStop { position: 10/12.0; color: Qt.hsva(10/12.0, 1, 1, 1) }
                            GradientStop { position: 11/12.0; color: Qt.hsva(11/12.0, 1, 1, 1) }
                            GradientStop { position: 12/12.0; color: Qt.hsva(12/12.0, 1, 1, 1) }
                        }
                    }
                    RadialGradient {
                        anchors.fill: parent
                        horizontalRadius: tagColorPickerPopup.wheelRadius
                        verticalRadius:   tagColorPickerPopup.wheelRadius
                        gradient: Gradient { 
                            GradientStop { position: 0.0; color: "#FFFFFFFF" }
                            GradientStop { position: 1.0; color: "#00FFFFFF" } 
                        }
                    }
                    Rectangle { anchors.fill: parent; radius: tagColorPickerPopup.wheelRadius; color: "black"; opacity: 1.0 - tagColorPickerPopup.val }
                    Item {
                        id: wheelCursor
                        width: 18
                        height: 18
                        x: tagColorPickerPopup.wheelRadius - 9
                        y: tagColorPickerPopup.wheelRadius - 9
                        Rectangle { anchors.fill: parent; radius: 9; color: "transparent"; border.color: "white"; border.width: 2.5 }
                        Rectangle { anchors.fill: parent; anchors.margins: 2.5; radius: 6.5; color: "transparent"; border.color: "#00000066"; border.width: 1.5 }
                        Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: "#00000066" }
                        Behavior on x { SmoothedAnimation { velocity: 400 } }
                        Behavior on y { SmoothedAnimation { velocity: 400 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        function _pick(mouse) {
                            var cx = tagColorPickerPopup.wheelRadius; var rX = mouse.x - cx; var rY = mouse.y - cx; var len = Math.sqrt(rX*rX + rY*rY)
                            if (len > cx) { rX *= cx / len; rY *= cx / len; len = cx }
                            wheelCursor.x = (cx + rX) - wheelCursor.width / 2; wheelCursor.y = (cx + rY) - wheelCursor.height / 2
                            var h = Math.atan2(rY, rX) / (2 * Math.PI); if (h < 0) h += 1.0
                            tagColorPickerPopup.hue = h; tagColorPickerPopup.sat = len / cx
                        }
                        onPressed: (m) => _pick(m); onPositionChanged: (m) => _pick(m)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "V"; font.family: root.monoFont; font.pixelSize: 11; color: "#A0AEC0"; font.weight: Font.Bold }
                Item {
                    Layout.fillWidth: true
                    height: 28
                    Rectangle {
                        id: valTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 10
                        radius: 5
                        clip: true
                        LinearGradient {
                            anchors.fill: parent; start: Qt.point(0, 0); end: Qt.point(parent.width, 0)
                            gradient: Gradient { 
                                GradientStop { position: 0.0; color: "#000000" }
                                GradientStop { position: 1.0; color: Qt.hsva(tagColorPickerPopup.hue, tagColorPickerPopup.sat, 1.0, 1.0) } 
                            }
                        }
                    }
                    Rectangle {
                        id: valHandle
                        width: 20
                        height: 20
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: tagColorPickerPopup.val * (parent.width - width)
                        color: tagColorPickerPopup.previewColor
                        border.color: "white"
                        border.width: 2.5
                        Behavior on color { ColorAnimation { duration: 50 } }
                        layer.enabled: true 
                        layer.effect: DropShadow { 
                            transparentBorder: true 
                            color: Qt.rgba(tagColorPickerPopup.previewColor.r, tagColorPickerPopup.previewColor.g, tagColorPickerPopup.previewColor.b, 0.55) 
                            radius: 7
                            samples: 14
                            verticalOffset: 2 
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        function _pick(m) { tagColorPickerPopup.val = Math.max(0.0, Math.min(1.0, m.x / parent.width)) }
                        onPressed: (m) => _pick(m); onPositionChanged: (m) => _pick(m)
                    }
                } 
                Text { text: Math.round(tagColorPickerPopup.val * 100) + "%"; font.family: root.monoFont; font.pixelSize: 11; color: "#A0AEC0"; width: 34; horizontalAlignment: Text.AlignRight }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.darker(root.themeBg, 1.06) }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: tagColorPickerPopup.previewColor
                    border.color: Qt.darker(tagColorPickerPopup.previewColor, 1.15)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    layer.enabled: true 
                    layer.effect: DropShadow { 
                        transparentBorder: true 
                        color: Qt.rgba(tagColorPickerPopup.previewColor.r, tagColorPickerPopup.previewColor.g, tagColorPickerPopup.previewColor.b, 0.35) 
                        radius: 7
                        samples: 14
                        verticalOffset: 2 
                    }
                }
                TextField {
                    id: hexInput; Layout.fillWidth: true; height: 32; font.family: root.monoFont; font.pixelSize: 13; color: "#2D3748"; leftPadding: 10
                    Connections { target: tagColorPickerPopup; function onPreviewColorChanged() { if (!hexInput.activeFocus) hexInput.text = tagColorPickerPopup.previewColor.toString().toUpperCase() } }
                    Component.onCompleted: { text = tagColorPickerPopup.previewColor.toString().toUpperCase() }
                    background: Rectangle { radius: 8; color: "#F7FAFC"; border.color: hexInput.activeFocus ? "#3182CE" : "#E2E8F0"; border.width: hexInput.activeFocus ? 1.5 : 1; Behavior on border.color { ColorAnimation { duration: 80 } } }
                    onAccepted: {
                        var c = Qt.color(text); if (!c.valid) return
                        tagColorPickerPopup.hue = (c.hsvHue < 0) ? 0 : c.hsvHue; tagColorPickerPopup.sat = c.hsvSaturation; tagColorPickerPopup.val = c.hsvValue
                        var angle = tagColorPickerPopup.hue * 2 * Math.PI; var dist = tagColorPickerPopup.sat * tagColorPickerPopup.wheelRadius
                        wheelCursor.x = (tagColorPickerPopup.wheelRadius + Math.cos(angle) * dist) - wheelCursor.width / 2; wheelCursor.y = (tagColorPickerPopup.wheelRadius + Math.sin(angle) * dist) - wheelCursor.height / 2
                        hexInput.focus = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 10; color: tagColorPickerPopup.originalColor
                    Text { anchors.centerIn: parent; text: "Before"; font.family: root.mainFont; font.pixelSize: 11; font.weight: Font.Medium; color: "white"; style: Text.Outline; styleColor: Qt.darker(tagColorPickerPopup.originalColor, 1.6) }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var c = tagColorPickerPopup.originalColor; tagColorPickerPopup.hue = (c.hsvHue < 0) ? 0 : c.hsvHue; tagColorPickerPopup.sat = c.hsvSaturation; tagColorPickerPopup.val = c.hsvValue
                            Qt.callLater(function() {
                                var angle = tagColorPickerPopup.hue * 2 * Math.PI; var dist = tagColorPickerPopup.sat * tagColorPickerPopup.wheelRadius
                                wheelCursor.x = (tagColorPickerPopup.wheelRadius + Math.cos(angle) * dist) - wheelCursor.width / 2; wheelCursor.y = (tagColorPickerPopup.wheelRadius + Math.sin(angle) * dist) - wheelCursor.height / 2
                            })
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 10; color: tagColorPickerPopup.previewColor; Behavior on color { ColorAnimation { duration: 80 } }
                    layer.enabled: true 
                    layer.effect: DropShadow { 
                        transparentBorder: true 
                        color: Qt.rgba(tagColorPickerPopup.previewColor.r, tagColorPickerPopup.previewColor.g, tagColorPickerPopup.previewColor.b, 0.50) 
                        radius: 12
                        samples: 24
                        verticalOffset: 4 
                    }
                    Text { anchors.centerIn: parent; text: "Apply ✓"; font.family: root.mainFont; font.pixelSize: 12; font.weight: Font.Bold; color: "white"; style: Text.Outline; styleColor: Qt.darker(tagColorPickerPopup.previewColor, 1.5) }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (tagColorPickerPopup.editingTagIndex >= 0) { tagModel.setProperty(tagColorPickerPopup.editingTagIndex, "colorCode", tagColorPickerPopup.previewColor.toString()); root.colorUpdateTrigger++ }
                            tagColorPickerPopup.close()
                        }
                    }
                }
            }
        } 
    } 

    // C. 系統背景主題色票盤
    Popup {
        id: arcColorPicker
        width: 220
        height: 140
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 12; color: "#FFFFFF"; border.color: "#E0E0E0"; layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#20000000"; radius: 15; samples: 30; verticalOffset: 4 } }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 15; spacing: 10
            Text { text: "Theme Color"; font.family: root.mainFont; font.pixelSize: 14; font.weight: Font.Bold; color: "#333" }
            GridLayout {
                columns: 5; columnSpacing: 10; rowSpacing: 10
                Repeater {
                    model: [ { bg: "#FFFFFF", sidebar: "#FAFAFA" }, { bg: "#FBF9F6", sidebar: "#F4EFEB" }, { bg: "#F2F7F4", sidebar: "#E8F0EA" }, { bg: "#F0F5FA", sidebar: "#E5EDF5" }, { bg: "#F6F2F9", sidebar: "#ECE5F0" }, { bg: "#FFF4F4", sidebar: "#FCE8E8" } ]
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: modelData.sidebar
                        border.color: "#DDD"
                        MouseArea { anchors.fill: parent; onClicked: { root.themeBg = modelData.bg; root.sidebarBg = modelData.sidebar } }
                    }
                }
            }
        }
    }
    // ── 💡 5秒後把終端機提示字恢復原狀的獨立定時器 ──
    Timer {
        id: hintResetTimer
        interval: 5000 // 5000 毫秒 = 5 秒
        onTriggered: {
            terminalPrompt.text = "Enter schedule (e.g., 明天 14-16 #Study, 2026/4/4 15:00-17:00 #LinearAlgebra -p hard -t study) or control via /find, /rm"
            terminalPrompt.color = "#8d8d8d" // 變回經典的極客灰色
        }
    }
}