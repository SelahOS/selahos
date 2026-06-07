pragma Singleton
import QtQuick

QtObject {
    // Background layers
    readonly property color background:      "#0B0F1A"
    readonly property color panel:           "#131926"
    readonly property color hover:           "#1E2840"
    readonly property color inputBackground: "#0F1420"

    // Accents
    readonly property color gold:            "#D6A85A"
    readonly property color teal:            "#8EC3B8"

    // Text
    readonly property color textPrimary:     "#EDE4D4"
    readonly property color textSecondary:   "#9A8D7B"

    // Borders / misc
    readonly property color border:          "#2A3042"
    readonly property color selectionBg:     "#D6A85A30"
    readonly property color userBubble:      "#1A2035"
    readonly property color aiBubble:        "#131926"

    // Typography
    readonly property string fontFamily:     "Inter"
    readonly property int    fontSm:         11
    readonly property int    fontMd:         13
    readonly property int    fontLg:         16
    readonly property int    fontXl:         20

    // Radii
    readonly property int    radSm:          4
    readonly property int    radMd:          8
    readonly property int    radLg:          12

    // Animation durations (ms)
    readonly property int    fast:           120
    readonly property int    normal:         200
}
