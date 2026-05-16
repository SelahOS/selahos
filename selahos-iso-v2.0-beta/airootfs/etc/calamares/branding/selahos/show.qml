import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function onActivate() {
        presentation.currentSlide = 0
    }

    function onLeave() { }

    Timer {
        interval: 8000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        anchors.fill: parent
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 80
            text: "Welcome to SelahOS"
            color: "#F1E8D8"
            font.family: "Manrope"
            font.pixelSize: 36
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 140
            text: "Pause. Reflect. Create."
            color: "#D6A85A"
            font.family: "Inter"
            font.italic: true
            font.pixelSize: 18
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.7
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "An operating system designed for creators.\n\nBuilt on Linux, opinionated about audio,\nhardware-adaptive by design.\n\nMade by Selah Technologies LLC."
            color: "#F1E8D8"
            font.family: "Inter"
            font.pixelSize: 15
        }
    }

    Slide {
        anchors.fill: parent
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 80
            text: "SelahBridge™"
            color: "#F1E8D8"
            font.family: "Manrope"
            font.pixelSize: 32
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.7
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "Drop a Windows installer.\n\nIt installs.\nIt opens.\nIt runs.\n\nMPC. Reaper. FL Studio. AIR plugins.\nAll on Linux."
            color: "#E2D4BF"
            font.family: "Inter"
            font.pixelSize: 16
        }
    }

    Slide {
        anchors.fill: parent
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 80
            text: "Hardware-Adaptive"
            color: "#F1E8D8"
            font.family: "Manrope"
            font.pixelSize: 32
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.7
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "Older Mac? Older PC? SelahOS adapts.\n\nGive your machine another decade of useful life.\n\nThe hardware you already own is enough."
            color: "#E2D4BF"
            font.family: "Inter"
            font.pixelSize: 16
        }
    }

    Slide {
        anchors.fill: parent
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 80
            text: "Your Audio, First-Class"
            color: "#F1E8D8"
            font.family: "Manrope"
            font.pixelSize: 32
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.7
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "PipeWire. JACK. ASIO.\nLow-latency by default.\n\nNative Linux DAWs and Windows software\nside-by-side through SelahBridge."
            color: "#E2D4BF"
            font.family: "Inter"
            font.pixelSize: 16
        }
    }

    Slide {
        anchors.fill: parent
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.7
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "Selah."
            color: "#D6A85A"
            font.family: "Manrope"
            font.italic: true
            font.pixelSize: 56
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 80
            text: "Pause. Reflect. Create."
            color: "#E2D4BF"
            font.family: "Inter"
            font.italic: true
            font.pixelSize: 18
        }
    }
}
