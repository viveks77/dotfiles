import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    
    readonly property int workspaceGroup: Math.floor((monitor?.activeWorkspace?.id - 1) / Config.options.bar.workspaces.shown)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 6
    property int workspaceButtonWidth: 26
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (monitor?.activeWorkspace?.id - 1) % Config.options.bar.workspaces.shown

    // Store the actual widths of workspace buttons
    property var workspaceButtonWidths: []

    property bool showNumbers: false
    Timer {
        id: showNumbersTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.showNumbers = true
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
            if (GlobalStates.superDown) showNumbersTimer.restart();
            else {
                showNumbersTimer.stop();
                root.showNumbers = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() { 
            showNumbersTimer.stop()
        }
    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: Config.options.bar.workspaces.shown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * Config.options.bar.workspaces.shown + i + 1);
        })
    }

    // Function to update button widths array
    function updateButtonWidth(index, width) {
        let newWidths = [...workspaceButtonWidths];
        while (newWidths.length <= index) {
            newWidths.push(workspaceButtonWidth);
        }
        newWidths[index] = width;
        workspaceButtonWidths = newWidths;
    }

    // Function to get the X position for a workspace index
    function getWorkspaceXPosition(index) {
        let x = 0;
        for (let i = 0; i < index && i < workspaceButtonWidths.length; i++) {
            x += workspaceButtonWidths[i] || workspaceButtonWidth;
        }
        return x;
    }

    // Initialize workspaceOccupied when the component is created
    Component.onCompleted: {
        updateWorkspaceOccupied();
        // Initialize button widths array
        workspaceButtonWidths = Array(Config.options.bar.workspaces.shown).fill(workspaceButtonWidth);
    }

    // Listen for changes in Hyprland.workspaces.values
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`workspace r+1`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`workspace r-1`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`togglespecialworkspace`);
            } 
        }
    }

    // Workspaces - background
    RowLayout {
        id: rowLayout
        z: 1

        spacing: 0
        anchors.fill: parent
        implicitHeight: Appearance.sizes.barHeight

        Repeater {
            model: Config.options.bar.workspaces.shown

            Rectangle {
                z: 1
                implicitWidth: workspaceButtonWidths[index] || workspaceButtonWidth
                implicitHeight: workspaceButtonWidth
                radius: Appearance.rounding.full
                property var leftOccupied: (workspaceOccupied[index-1] && !(!activeWindow?.activated && monitor?.activeWorkspace?.id === index))
                property var rightOccupied: (workspaceOccupied[index+1] && !(!activeWindow?.activated && monitor?.activeWorkspace?.id === index+2))
                property var radiusLeft: leftOccupied ? 0 : Appearance.rounding.full
                property var radiusRight: rightOccupied ? 0 : Appearance.rounding.full

                topLeftRadius: radiusLeft
                bottomLeftRadius: radiusLeft
                topRightRadius: radiusRight
                bottomRightRadius: radiusRight
                
                color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
                opacity: (workspaceOccupied[index] && !(!activeWindow?.activated && monitor?.activeWorkspace?.id === index+1)) ? 1 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on radiusLeft {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                Behavior on radiusRight {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
            }
        }
    }

    // Active workspace
    Rectangle {
        z: 2
        // Make active ws indicator, which has a brighter color, smaller to look like it is of the same size as ws occupied highlight
        property real activeWorkspaceMargin: 2
        implicitHeight: workspaceButtonWidth - activeWorkspaceMargin * 2
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary
        anchors.verticalCenter: parent.verticalCenter

        // Calculate position and width based on actual button widths
        x: root.getWorkspaceXPosition(workspaceIndexInGroup) + activeWorkspaceMargin
        implicitWidth: (workspaceButtonWidths[workspaceIndexInGroup] || workspaceButtonWidth) - activeWorkspaceMargin * 2

        Behavior on activeWorkspaceMargin {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutSine
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutSine
            }
        }
    }

    // Workspaces - numbers
    RowLayout {
        id: rowLayoutNumbers
        z: 3

        spacing: 0
        anchors.fill: parent
        implicitHeight: Appearance.sizes.barHeight

        Repeater {
            id: workspaceRepeater
            model: Config.options.bar.workspaces.shown

            Button {
                id: button
                property int workspaceValue: workspaceGroup * Config.options.bar.workspaces.shown + index + 1
                Layout.fillHeight: true
                onPressed: Hyprland.dispatch(`workspace ${workspaceValue}`)
                
                // Calculate width based on number of icons
                property int calculatedWidth: {
                    let count = workspaceButtonBackground.windowsInWorkspace.length
                    if (count === 0 || !Config.options?.bar.workspaces.showAppIcons) {
                        return workspaceButtonWidth
                    }
                    let iconsWidth = count * workspaceIconSizeShrinked + (count - 1) * 1
                    return Math.max(workspaceButtonWidth, iconsWidth + 8) // padding
                }
                
                width: calculatedWidth
                
                // Update the button width in the parent array whenever it changes
                onCalculatedWidthChanged: {
                    root.updateButtonWidth(index, calculatedWidth)
                }
                
                background: Item {
                    id: workspaceButtonBackground
                    implicitWidth: button.calculatedWidth
                    implicitHeight: workspaceButtonWidth
                    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(button.workspaceValue)
                    property var mainAppIconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")
                    
                    function getUniqueWindows(workspaceId) {
                        const windows = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
                        const uniqueApps = {};
                        windows.forEach(win => {
                            const appClass = AppSearch.guessIcon(win.class);
                            if (uniqueApps[appClass]) {
                                uniqueApps[appClass].count++;
                            } else {
                                uniqueApps[appClass] = {
                                    class: win.class,
                                    icon: appClass,
                                    count: 1,
                                };
                            }
                        });
                        return Object.values(uniqueApps);
                    }
                    property var windowsInWorkspace: getUniqueWindows(button.workspaceValue)

                    StyledText { // Workspace number text
                        opacity: root.showNumbers
                            || ((Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !workspaceButtonBackground.biggestWindow || root.showNumbers))
                            || (root.showNumbers && !Config.options?.bar.workspaces.showAppIcons)
                            )  ? 1 : 0
                        z: 3

                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                        text: `${button.workspaceValue}`
                        elide: Text.ElideRight
                        color: (monitor?.activeWorkspace?.id == button.workspaceValue) ? 
                            Appearance.m3colors.m3onPrimary : 
                            (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                                Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    Rectangle { // Dot instead of ws number
                        id: wsDot
                        opacity: (Config.options?.bar.workspaces.alwaysShowNumbers
                            || root.showNumbers
                            || (Config.options?.bar.workspaces.showAppIcons && workspaceButtonBackground.biggestWindow)
                            ) ? 0 : 1
                        visible: opacity > 0
                        anchors.centerIn: parent
                        width: workspaceButtonWidth * 0.18
                        height: width
                        radius: width / 2
                        color: (monitor?.activeWorkspace?.id == button.workspaceValue) ? 
                            Appearance.m3colors.m3onPrimary : 
                            (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                                Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    Row {
                        anchors.centerIn: parent
                        spacing: 1
                        visible: Config.options?.bar.workspaces.showAppIcons && workspaceButtonBackground.windowsInWorkspace.length > 0
                        opacity: root.showNumbers ? 0 : 1

                                                Repeater {
                            model: workspaceButtonBackground.windowsInWorkspace
                            Image {
                                id: iconImage
                                required property var modelData
                                width: workspaceIconSizeShrinked
                                height: width
                                anchors.verticalCenter: parent.verticalCenter
                                source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                sourceSize: Qt.size(width, height)
                                fillMode: Image.PreserveAspectFit

                                property color baseColor: (monitor?.activeWorkspace?.id == button.workspaceValue) ?
                                    Appearance.m3colors.m3onPrimary :
                                    (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer :
                                        Appearance.m3colors.m3Primary)
                            }
                        }
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                }
            }
        }
    }
}