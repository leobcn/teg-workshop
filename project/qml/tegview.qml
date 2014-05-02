import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import TegView 1.0
import 'tegrender.js' as Renderer

ApplicationWindow {
    id: view
    width: 700
    height: 600
    color: "#ecf0f1"
    property alias ctrl: ctrl
    property alias editMode: editbtn.checked
    property alias viewMode: viewbtn.checked

    toolBar: ToolBar {
        RowLayout {
            ToolButton {
                text: "+"
                onClicked: cv.zoom += 0.2
            }
            ToolButton {
                text: "-"
                onClicked: cv.zoom -= 0.2
            }
            ToolButton {
                text: "Rand"
                onClicked: {
                    for(var p in model.places) {
                        model.places[p].counter = rand(0,12)
                        model.places[p].timer = rand(0,12)
                        cv.requestPaint()
                    }
                }

                function rand(min, max) {
                    return Math.floor(Math.random() * (max - min + 1)) + min;
                }
            }
            Rectangle {
                width: 3
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                color: "#34495e"
            }
            ExclusiveGroup { id: mode }
            RadioButton {
                id: viewbtn
                exclusiveGroup: mode
                text: "View"
            }
            RadioButton {
                id: editbtn
                checked: true
                exclusiveGroup: mode
                text: "Edit"
            }
        }
    }

    Ctrl {
        id: ctrl
        canvasWidth: cv.canvasSize.width
        canvasHeight: cv.canvasSize.height
        canvasWindowX: cv.canvasWindow.x
        canvasWindowY: cv.canvasWindow.y
        canvasWindowHeight: cv.canvasWindow.height
        canvasWindowWidth: cv.canvasWindow.width
        zoom: cv.zoom
    }

    RowLayout {
        id: keyHintRow
        z: 2
        property string fontColor: "#34495e"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.bottomMargin: 10
        spacing: 10
        Text {
            id: ctrlIndicator
            text: "Ctrl"
            font.capitalization: Font.SmallCaps
            font.pointSize: 16
            color: keyHintRow.fontColor
            visible: ctrl.modifierKeyControl
        }

        Text {
            id: altIndicator
            text: (ctrlIndicator.visible ? "+ ": "") + "Alt"
            font.capitalization: Font.SmallCaps
            font.pointSize: 16
            color: keyHintRow.fontColor
            visible: ctrl.modifierKeyAlt
        }

        Text {
            id: shiftIndicator
            text: ((ctrlIndicator.visible || altIndicator.visible)  ? "+ ": "") + "Shift"
            font.pointSize: 16
            font.capitalization: Font.SmallCaps
            color: keyHintRow.fontColor
            visible: ctrl.modifierKeyShift
        }

        Text {
            id: keyHint
            font.pointSize: 16
            font.capitalization: Font.SmallCaps
            color: keyHintRow.fontColor
            visible: false

            function setText(text) {
                if(text.length > 0) {
                    this.visible = true
                    this.text = ((ctrlIndicator.visible || altIndicator.visible || shiftIndicator.visible)  ? "+ ": "")
                    this.text += text
                } else {
                    this.visible = false
                    this.text = ""
                }
            }
        }
    }

    Text {
        id: modeHint
        font.pointSize: 20
        font.capitalization: Font.SmallCaps
        color: "#b4b4b4"
        text: editMode ? "Edit mode" : "View mode"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.topMargin: 15
    }

    /*
    Image {
        anchors.fill: parent
        fillMode: Image.Tile
        source: "grid.png"
    }
    */

    Canvas {
        id: cv
        property real zoom: 1.0
        anchors.fill: parent
        canvasSize.height: 16536 * scale
        canvasSize.width: 16536 * scale
        canvasWindow.width: width
        canvasWindow.height: height
        tileSize: "1024x1024"
        onPaint: Renderer.render(cv, region, zoom, model)


        Component.onCompleted: {
            canvasWindow.x = canvasSize.width / 2
            canvasWindow.y = canvasSize.height / 2
            coldstart.start()
        }

        onZoomChanged: {
            cv.requestPaint()
        }

        focus: true
        Keys.onPressed: {
            ctrl.modifierKeyShift = (event.modifiers & Qt.ShiftModifier) ? true : false
            ctrl.modifierKeyControl = (event.modifiers & Qt.ControlModifier) ? true : false
            ctrl.modifierKeyAlt = (event.modifiers & Qt.AltModifier) ? true : false

            if(ctrl.modifierKeyControl && event.key === Qt.Key_V) {
                viewbtn.checked = true
            } else if (ctrl.modifierKeyControl && event.key === Qt.Key_E) {
                editbtn.checked = true
            } else {
                ctrl.keyPressed(event.key, event.text)
            }

            if(ctrl.modifierKeyControl) {
                keyHint.setText(event.text)
            }
            event.accepted = true
        }
        Keys.onReleased: {
            ctrl.modifierKeyShift = (event.modifiers & Qt.ShiftModifier) ? true : false
            ctrl.modifierKeyControl = (event.modifiers & Qt.ControlModifier) ? true : false
            ctrl.modifierKeyAlt = (event.modifiers & Qt.AltModifier) ? true : false

            keyHint.setText("")
            event.accepted = true
            cv.requestPaint()
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            property real dragOffset: 50.0
            property int cx0
            property int cy0
            property int x0
            property int y0

            onPressed: {
                if(viewMode) {
                    cx0 = cv.canvasWindow.x
                    cy0 = cv.canvasWindow.y
                    x0 = mouse.x
                    y0 = mouse.y
                } else if(editMode) {
                    ctrl.mousePressed(mouse.x, mouse.y)
                }
            }

            onPositionChanged: {
                if(x0 != mouse.x || y0 != mouse.y) {
                    if (viewMode) {
                        cv.canvasWindow.x = cx0 + (x0 - mouse.x)
                        cv.canvasWindow.y = cy0 + (y0 - mouse.y)
                        cv.requestPaint()
                    } else if(editMode) {
                        if(mouse.x < 0 + dragOffset) {
                            cv.canvasWindow.x += -5.0
                        } else if(mouse.x > cv.canvasWindow.width - dragOffset) {
                            cv.canvasWindow.x += 5.0
                        }
                        if(mouse.y < 0 + dragOffset) {
                            cv.canvasWindow.y += -5.0
                        } else if(mouse.y > cv.canvasWindow.height - dragOffset) {
                            cv.canvasWindow.y += 5.0
                        }
                        ctrl.mouseMoved(mouse.x, mouse.y)
                    }
                }
            }

            onReleased: {
                if (editMode) {
                    ctrl.mouseReleased(mouse.x, mouse.y)
                }
            }

            onDoubleClicked: {
                if (editMode) {
                    ctrl.mouseDoubleClicked(mouse.x, mouse.y)
                }
            }
        }

        Timer {
            id: coldstart
            interval: 1000
            onTriggered: cv.requestPaint()
            repeat: false
        }
    }

    Item {
        id: model
        property var data
        property var updated: baseTeg.updated
        property var magicStroke: baseTeg.magicStroke
        property var magicStrokeUsed: baseTeg.magicStrokeUsed
        property var magicRectUsed: baseTeg.magicRectUsed
        property var altPressed: ctrl.modifierKeyAlt

        onUpdatedChanged: {
            model.data = prepareModel(baseTeg)
            cv.requestPaint()
        }

        function preparePlaceSpec(spec) {
            return {
                "x": spec.x, "y": spec.y,
                "place": true, "selected": spec.selected,
                "counter": spec.counter, "timer": spec.timer,
                "in_control": spec.inControl ? {"x": spec.inControl.x, "y": spec.inControl.y} : undefined,
                "out_control": spec.outControl ? {"x": spec.outControl.x, "y": spec.outControl.y} : undefined,
                "label": spec.label
            }
        }

        function prepareTransitionSpec(spec) {
            return {
                "x": spec.x, "y": spec.y, "in": spec.in, "out": spec.out,
                "transition": true, "selected": spec.selected, "horizontal": spec.horizontal,
                "label": spec.label
            }
        }

        function prepareGroupSpec(spec) {
            return {
                "x": spec.x, "y": spec.y, "collapsed": spec.collapsed,
                "selected": spec.selected, "label": spec.label, data: prepareModel(spec.model),
                "width": spec.width, "height": spec.height,
            }
        }

        function prepareModel(m) {
            var data = {"transitions": [], "places": [], "arcs": [], "groups": []}

            for(var i = 0; i < m.placesLen; i++) {
                data.places[i] = preparePlaceSpec(m.getPlaceSpec(i))
            }
            for(var i = 0; i < m.groupsLen; i++) {
                data.groups[i] = prepareGroupSpec(m.getGroupSpec(i))
            }
            for(var i = 0; i < m.transitionsLen; i++) {
                var spec = m.getTransitionSpec(i)
                var arcspecs = spec.arcSpecs
                data.transitions[i] = prepareTransitionSpec(spec)

                for(var j = 0; j < arcspecs.length; ++j){
                    var a = arcspecs.value(j)
                    data.arcs.push({"place": preparePlaceSpec(a.place), "transition": data.transitions[i],
                                       "index": a.index, "inbound": a.inbound})
                }
            }

            return data
        }
    }
}

