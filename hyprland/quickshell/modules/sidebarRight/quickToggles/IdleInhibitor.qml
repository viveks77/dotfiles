import qs.modules.common
import qs.modules.common.widgets
import qs
import Quickshell.Io
import Quickshell

QuickToggleButton {
    id: root
    toggled: false
    buttonIcon: "coffee"
    onClicked: {
        if (toggled) {
            root.toggled = false
            Quickshell.execDetached(["pkill", "-f", "wayland-idle-inhibitor.py"])
        } else {
            root.toggled = true
            Quickshell.execDetached([`${Directories.scriptPath}/wayland-idle-inhibitor.py`])
        }
    }
    Process {
        id: fetchActiveState
        running: true
        command: ["pidof", "wayland-idle-inhibitor.py"]
        onExited: (exitCode, exitStatus) => {
            root.toggled = exitCode === 0
        }
    }
    StyledToolTip {
        content: Translation.tr("Keep system awake")
    }
}
