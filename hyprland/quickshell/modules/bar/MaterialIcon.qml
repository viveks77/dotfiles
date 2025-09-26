import qs
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

StyledText {
    property real fill
    property int grade: Appearance.m3colors.m3outlineVariant ? 0 : -25

    font.family: Appearance.font.family.material
    font.pixelSize: Appearance.font.pixelSize.large
    font.variableAxes: ({
            FILL: fill.toFixed(1),
            GRAD: grade,
            opsz: Appearance.font.pixelSize.large,
            wght: Font.demiBold
        })
}