import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "local.worldtimechum"
    readonly property bool opened: panel.opened
    readonly property bool popoutSwitchClosing: panel.popoutSwitchClosing
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    function open() { panel.open() }
    function close() { panel.close() }
    function closeForPopoutSwitch() { panel.closeForPopoutSwitch() }
    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "󰖟"
        fontSize: Style.font.icon
        tooltipText: "WorldTimeChum"
        onPressed: panel.toggle()
    }
    TimePanel {
        id: panel
        bar: root.bar
        settings: root.settings
        anchorItem: button
        hostWidget: root
    }
    IpcHandler {
        target: "local.worldtimechum"
        function toggle(): void { panel.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }
}
