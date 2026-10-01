import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Selection.js" as Selection

Panel {
    id: root
    moduleName: "local.worldtimechum"
    ipcTarget: "local.worldtimechum"
    manageIpc: false
    property var anchorItem: null
    property var hostWidget: null
    property var snapshotData: ({rows: [], catalog: []})
    property int dayOffset: 0
    property int selected: -1
    property int selectionEnd: -1
    property int hovered: -1
    readonly property int currentColumn: snapshotData.currentColumn || 0
    readonly property real currentPosition: snapshotData.currentPosition || 0
    readonly property int activeSlot: hovered >= 0 ? hovered : (selected >= 0 ? selected : currentColumn * 2)
    readonly property int activeColumn: Math.floor(activeSlot / 2)
    readonly property int borderStart: selected >= 0 ? selected : activeSlot
    readonly property int borderEnd: selected >= 0 ? selectionEnd : borderStart + 1
    property string error: ""
    property string copied: ""
    property var requestedZones: []
    property int requestedDay: 0
    readonly property var zones: setting("zones", ["Australia/Adelaide", "Europe/London", "America/New_York", "Asia/Tokyo"])
    readonly property bool twelveHour: setting("timeFormat", "24h") === "12h"
    function formatTime(time, includePeriod) {
        if (!twelveHour) return time
        var parts = time.split(":")
        var hour = Number(parts[0])
        return String(hour % 12 || 12) + ":" + parts[1] + (includePeriod === false ? "" : (hour < 12 ? " AM" : " PM"))
    }
    function formattedLabel(cell) { return cell.label.replace(cell.time, formatTime(cell.time)) }
    function setTimeFormat(value) {
        var entry = {id: moduleName}
        for (var key in settings) entry[key] = settings[key]
        entry.timeFormat = value
        settings = entry
        if (hostWidget) hostWidget.settings = entry
        if (bar && bar.shell) bar.shell.updateEntryInline(moduleName, entry)
        copied = ""
    }
    function open() { refresh(); controller.show() }
    function close() { hovered = -1; controller.hide() }
    function toggle() { if (opened) close(); else open() }
    function refresh() {
        if (worker.running) return
        requestedZones = zones.slice()
        requestedDay = dayOffset
        worker.command = ["python3", Qt.resolvedUrl("timezones.py").toString().replace(/^file:\/\//, ""), JSON.stringify(zones), String(dayOffset)]
        worker.running = true
    }
    function save(next) {
        var entry = {id: moduleName}
        for (var key in settings) entry[key] = settings[key]
        entry.zones = next
        settings = entry
        if (hostWidget) hostWidget.settings = entry
        if (bar && bar.shell) bar.shell.updateEntryInline(moduleName, entry)
        selected = -1
        Qt.callLater(refresh)
    }
    function step(delta) { dayOffset += delta; selected = -1; refresh() }
    function selectionText() {
        if (selected < 0) return ""
        return snapshotData.rows.map(function(row) {
            return row.city + ": " + root.formattedLabel(row.boundaries[selected]) + " – " + root.formattedLabel(row.boundaries[selectionEnd])
        }).join("\n")
    }
    Process {
        id: worker
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var result = JSON.parse(text)
                    if (result.error) root.error = result.error
                    else { root.snapshotData = result; root.error = "" }
                } catch (e) { root.error = "Could not read timezone data: " + e }
            }
        }
        onExited: function(code, status) {
            if (code !== 0) root.error = "Timezone helper failed. Check python3 and system tzdata."
            if (JSON.stringify(root.requestedZones) !== JSON.stringify(root.zones) || root.requestedDay !== root.dayOffset) Qt.callLater(root.refresh)
        }
    }
    Process {
        id: clipboard
        onExited: function(code, status) {
            if (code === 0) { root.copied = "Copied!"; copyTimer.restart() }
            else root.error = "Could not copy the selection. Check wl-copy is installed."
        }
    }
    Timer { interval: 60000; repeat: true; running: root.opened; onTriggered: root.refresh() }
    KeyboardPanel {
        id: popup
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        centerOnBar: true
        focusTarget: content
        contentWidth: availableCardWidth > 0 ? Math.round(availableCardWidth) : 1240
        contentHeight: fittedContentHeight(body.implicitHeight)
        Flickable {
            id: content
            anchors.fill: parent
            contentWidth: body.width
            contentHeight: body.height
            clip: true
            focus: true
            Keys.onEscapePressed: root.close()
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: body
                width: Math.max(content.width, 780)
                spacing: Style.space(16)
                Item {
                    width: body.width
                    height: Math.max(appTitle.implicitHeight, dayNavigation.implicitHeight)
                    ChumText {
                        id: appTitle
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "WorldTimeChum"
                        font.pixelSize: Style.space(30)
                        font.bold: true
                    }
                    Row {
                        id: dayNavigation
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(12)
                        Button { anchors.verticalCenter: parent.verticalCenter; text: "24h"; selected: !root.twelveHour; focusable: true; onClicked: root.setTimeFormat("24h") }
                        Button { anchors.verticalCenter: parent.verticalCenter; text: "12h"; selected: root.twelveHour; focusable: true; onClicked: root.setTimeFormat("12h") }
                        PanelActionButton { anchors.verticalCenter: parent.verticalCenter; iconText: "󰅁"; tooltipText: "Previous day"; onClicked: root.step(-1) }
                        Button { anchors.verticalCenter: parent.verticalCenter; text: "Today"; focusable: true; onClicked: { root.dayOffset = 0; root.selected = -1; root.refresh() } }
                        PanelActionButton { anchors.verticalCenter: parent.verticalCenter; iconText: "󰅂"; tooltipText: "Next day"; onClicked: root.step(1) }
                        PanelActionButton { anchors.verticalCenter: parent.verticalCenter; iconText: "󰅖"; tooltipText: "Close"; onClicked: root.close() }
                    }
                }
                ChumText { text: (root.snapshotData.date || "Loading…") + " · home midnight"; opacity: 0.65; font.pixelSize: Style.font.bodySmall }
                Rectangle { width: body.width; height: Style.spacing.hairline; color: Color.foreground; opacity: 0.12 }
                Row {
                    spacing: Style.space(12)
                    SearchableDropdown {
                        id: picker
                        width: Style.space(340)
                        showLabel: false
                        placeholderText: "Search cities or time zones…"
                        triggerLabel: value || "Add a city…"
                        options: root.snapshotData.catalog.map(function(zone) { return { value: zone, label: zone.replace(/_/g, " ") } })
                        onChanged: function(value) { picker.value = value }
                    }
                    Button {
                        id: add
                        text: "Add"
                        focusable: true
                        enabled: root.zones.length < 12 && picker.value !== ""
                        onClicked: {
                            var zone = picker.value
                            if (root.snapshotData.catalog.indexOf(zone) < 0) { root.error = "Select a valid IANA zone from the list."; return }
                            if (root.zones.indexOf(zone) >= 0) { root.error = "That city is already added."; return }
                            root.save(root.zones.concat([zone]))
                        }
                    }
                    Button {
                        focusable: true
                        text: root.copied || "Copy selected range"
                        enabled: root.selected >= 0
                        onClicked: {
                            clipboard.command = ["wl-copy", "--", root.selectionText()]
                            clipboard.running = true
                        }
                    }
                }
                ChumText { visible: root.error !== ""; text: root.error; color: Color.urgent; wrapMode: Text.Wrap; width: body.width }
                Item {
                    id: comparison
                    width: body.width
                    height: markerHeight + cityRows.implicitHeight
                    readonly property real markerHeight: Style.space(20)
                    readonly property real detailsWidth: Style.space(260)
                    readonly property real timelineWidth: width - detailsWidth
                    readonly property real pitch: timelineWidth / 25
                    readonly property real rowHeight: Style.space(66)
                    Column {
                        id: cityRows
                        y: comparison.markerHeight
                        width: parent.width
                        spacing: Style.space(2)
                        Repeater {
                            model: root.snapshotData.rows
                            Item {
                                id: cityRow
                                required property var modelData
                                required property int index
                                width: comparison.width
                                height: comparison.rowHeight
                                Column {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: comparison.detailsWidth - Style.space(60)
                                    spacing: Style.space(3)
                                    ChumText { width: parent.width; elide: Text.ElideRight; text: cityRow.modelData.city; font.bold: true }
                                    ChumText { text: root.formatTime(cityRow.modelData.time) + " " + cityRow.modelData.abbreviation; opacity: 0.7; font.pixelSize: Style.font.bodySmall }
                                    ChumText { text: cityRow.modelData.date; opacity: 0.5; font.pixelSize: Style.font.caption }
                                }
                                Row {
                                    x: comparison.detailsWidth - width - Style.space(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    PanelActionButton { iconText: "󰋜"; tooltipText: cityRow.index === 0 ? "Home city" : "Make home city"; enabled: cityRow.index > 0; onClicked: { var next = root.zones.slice(); next.splice(cityRow.index, 1); next.unshift(cityRow.modelData.zone); root.save(next) } }
                                    PanelActionButton { iconText: "󰅖"; tooltipText: "Remove city"; enabled: root.zones.length > 1; onClicked: { var next = root.zones.slice(); next.splice(cityRow.index, 1); root.save(next) } }
                                }
                                Row {
                                    x: comparison.detailsWidth
                                    spacing: Style.space(2)
                                    Repeater {
                                        model: cityRow.modelData.cells
                                        Rectangle {
                                            required property var modelData
                                            required property int index
                                            width: comparison.pitch - Style.space(2)
                                            height: comparison.rowHeight
                                            radius: Style.cornerRadius
                                            color: modelData.work ? Util.alpha(Color.accent, 0.17)
                                                : modelData.awake ? Util.alpha(Color.foreground, 0.07) : "transparent"
                                            Column {
                                                anchors.centerIn: parent
                                                spacing: Style.space(4)
                                                ChumText {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: root.formatTime(modelData.time, false)
                                                    opacity: root.activeColumn === index || (root.selected >= 0 && index * 2 < root.selectionEnd && index * 2 + 2 > root.selected) || modelData.awake ? 1 : 0.4
                                                    font.pixelSize: Style.font.caption
                                                    font.bold: root.activeColumn === index || (root.selected >= 0 && index * 2 < root.selectionEnd && index * 2 + 2 > root.selected)
                                                }
                                                ChumText {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    visible: root.twelveHour
                                                    text: Number(modelData.time.split(":")[0]) < 12 ? "AM" : "PM"
                                                    font.pixelSize: Style.font.caption
                                                    opacity: 0.5
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    ChumText {
                        x: comparison.detailsWidth + root.currentPosition * comparison.pitch - width / 2
                        y: 0
                        width: Style.space(18)
                        height: comparison.markerHeight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "󰅀"
                        color: Color.accent
                        font.pixelSize: Style.font.icon
                        visible: root.snapshotData.rows.length > 0
                    }
                    // Current time owns the fill; hover/copy selection owns
                    // the independent outline.
                    Rectangle {
                        x: comparison.detailsWidth + root.currentColumn * comparison.pitch
                        y: comparison.markerHeight
                        width: comparison.pitch - Style.space(2)
                        height: cityRows.implicitHeight
                        radius: Style.cornerRadius
                        color: Util.alpha(Color.accent, 0.14)
                        visible: root.snapshotData.rows.length > 0
                    }
                    Rectangle {
                        x: comparison.detailsWidth + root.borderStart * comparison.pitch / 2
                        y: comparison.markerHeight
                        width: (root.borderEnd - root.borderStart) * comparison.pitch / 2 - Style.space(2)
                        height: cityRows.implicitHeight
                        radius: Style.cornerRadius
                        color: "transparent"
                        border.color: Color.accent
                        border.width: Math.max(1, Style.spacing.hairline)
                        visible: root.selected >= 0 && root.snapshotData.rows.length > 0
                    }
                    MouseArea {
                        id: timelinePointer
                        x: comparison.detailsWidth
                        y: comparison.markerHeight
                        width: comparison.timelineWidth
                        height: cityRows.implicitHeight
                        hoverEnabled: true
                        preventStealing: true
                        acceptedButtons: Qt.LeftButton
                        property int dragAnchor: -1
                        property string dragMode: ""
                        property int originalStart: -1
                        property int originalEnd: -1
                        function edgeAt(x) { return Selection.edgeAt(x, comparison.pitch, root.selected, root.selectionEnd, Math.min(Style.space(8), comparison.pitch / 5)) }
                        cursorShape: dragMode === "start" || dragMode === "end" || edgeAt(mouseX) !== "" ? Qt.SizeHorCursor : Qt.PointingHandCursor
                        readonly property int hoveredRow: Math.max(0, Math.min(root.snapshotData.rows.length - 1, Math.floor(mouseY / (comparison.rowHeight + Style.space(2)))))
                        function updateColumn(x) { root.hovered = Selection.slotAt(x, comparison.pitch) }
                        function updateRange(x) {
                            var range = dragMode === "start" || dragMode === "end"
                                ? Selection.resizeRange(originalStart, originalEnd, dragMode, Selection.boundaryAt(x, comparison.pitch))
                                : Selection.rangeFrom(dragAnchor, Selection.slotAt(x, comparison.pitch))
                            root.selected = range.start
                            root.selectionEnd = range.end
                            root.copied = ""
                        }
                        onPressed: function(mouse) {
                            dragMode = edgeAt(mouse.x)
                            originalStart = root.selected
                            originalEnd = root.selectionEnd
                            dragAnchor = Selection.slotAt(mouse.x, comparison.pitch)
                            updateRange(mouse.x)
                        }
                        onPositionChanged: function(mouse) { updateColumn(mouse.x); if (pressed) updateRange(mouse.x) }
                        onEntered: updateColumn(mouseX)
                        onExited: root.hovered = -1
                        onReleased: function(mouse) { updateRange(mouse.x); root.hovered = -1; dragAnchor = -1; dragMode = "" }
                        onCanceled: { root.hovered = -1; dragAnchor = -1; dragMode = "" }
                        PanelToolTip {
                            visible: timelinePointer.containsMouse && root.snapshotData.rows.length > 0
                            text: {
                                if (root.snapshotData.rows.length === 0) return ""
                                var row = root.snapshotData.rows[timelinePointer.hoveredRow]
                                return root.formattedLabel(row.boundaries[root.borderStart]) + " – " + root.formattedLabel(row.boundaries[root.borderEnd])
                            }
                        }
                    }
                    Repeater {
                        model: root.selected >= 0 ? [root.selected, root.selectionEnd] : []
                        Rectangle {
                            required property int modelData
                            x: comparison.detailsWidth + modelData * comparison.pitch / 2 - width / 2 - (modelData === root.selectionEnd ? Style.space(2) : 0)
                            y: comparison.markerHeight + (cityRows.implicitHeight - height) / 2
                            width: Style.space(5)
                            height: Style.space(20)
                            radius: Style.cornerRadius
                            color: Color.accent
                        }
                    }
                }
                Rectangle { width: body.width; height: Style.spacing.hairline; color: Color.foreground; opacity: 0.12 }
                ChumText { text: "Column tint: current home time   ·   Drag to select; drag either edge to resize   ·   30-minute steps"; opacity: 0.5; font.pixelSize: Style.font.caption }
            }
        }
    }
    Timer { id: copyTimer; interval: 2000; onTriggered: root.copied = "" }
}
