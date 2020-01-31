import QtQuick 2.0
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.3
import QtCharts 2.3

ChartView{
    focus: true
    property var manager
    property var currentSeries: {[]}
    property int autoScaleCodeX: 0
    property int autoScaleCodeY: 0
    property int zoomCodeX: 1111
    property int zoomCodeY: 1111
    property int panCodeX: 1111
    property int panCodeY: 1111
    // codes are numbers going from 0 to 1111. They are formed this way:
    //
    states: [
        State {
            name: "empty" //This state is used to
            PropertyChanges { target: dynamoMenu; visible: false }
        },
        State {
            name: "measuring" // This is the state to be used when new points are fed to the plot
            PropertyChanges { target: dynamoMenu; visible: false }
        },
        State {
            name: "filled" // This state has to be used when the plot has been filled and no other point is going to be added
            PropertyChanges { target: dynamoMenu; visible: true }
        }
    ]
    // Sets the chart state
    function setState(newState){
        state = newState;
    }
    // Adds a series to the chart
    // @param params Dictionary:
    function addNewSeries(params){
        var newSeries; // = createSeries(type,name);
        var theX;
        var theY;
        switch(params.plotType){
            case "linlin":
                theX = params.bottom ? xAxisB : xAxisT;
                theY = params.left ? yAxisL : yAxisR;
                break;
            case "loglog":
                theX = params.bottom ? xLogAxisB : xLogAxisT;
                theY = params.left ? yLogAxisL : yLogAxisR;
                break;
            case "linlog":
                theX = params.bottom ? xAxisB : xAxisT;
                theY = params.left ? yLogAxisL : yLogAxisR;
                break;
            case "loglin":
                theX = params.bottom ? xLogAxisB : xLogAxisT;
                theY = params.left ? yAxisL : yAxisR;
                break;
        }
        newSeries = createSeries(params.type,params.name,theX,theY);
        newSeries.pointsVisible = params.points;
        newSeries.color = params.color;
        var toSend = params;
        params.series = newSeries;
        manager.addSeries(params);
        currentSeries.push(params.name);

        return newSeries
    }
    function addMultipleSeries(seriesContainer){
        for(var s in seriesContainer["seriesList"]){
            addNewSeries(seriesContainer["seriesList"][s]);
        }
    }
    function associateAxis(){
        manager.xBottom = xAxisB;
        manager.yLeft = yAxisL;
        manager.xTop = xAxisT;
        manager.yRight = yAxisR;

        manager.xLogBottom = xLogAxisB;
        manager.yLogLeft = yLogAxisL;
        manager.xLogTop = xLogAxisT;
        manager.yLogRight = yLogAxisR;

        manager.axisAssigned = true;
    }
    function smartClear(){
        manager.clear();
        for (var s in currentSeries){
            var toRemove = series(currentSeries[s]);
            removeSeries(toRemove);
        }
    }
    function switchRemote(switchOn){
        dynamoMouse.actOnXAuto = false;
        dynamoMouse.actOnYAuto = false;
        autoXMenuItem.checked = false;
        autoYMenuItem.checked = false;
        dynamoMouse.actOnXAuto = true;
        dynamoMouse.actOnYAuto = true;
        lxrMenuItem.checked = false;
        lyrMenuItem.checked = false;
        interactive = switchOn;
    }
    function grabPlot(){
        if (state === "plotting" || state === "filled"){
            cursorShape = Qt.ClosedHandCursor;
            dynamoMouse.oldX = dynamoMouse.mouseX;
            dynamoMouse.oldY = dynamoMouse.mouseY;
        }
    }
    function dynamoZoom(verse){
        var mouseP = Qt.point(mouseX, mouseY);
        var mouseMapped = parent.mapToValue(mouseP, parent.series(seriesNum-1));
        var toSend = {"verse": verse,
            "mouseX": mouseMapped.x,
            "mouseY": mouseMapped.y,"direction":""};
        if(onX && !onY && responsiveX){
            toSend["direction"] = "x";
        }
        else if(onY && !onX && responsiveY){
            toSend["direction"] = "y";
        }
        else if(onX && onY && (responsiveX || responsiveY)){
            if(responsiveX && !responsiveY){
                toSend["direction"] = "x";
            }
            else if(responsiveY && !responsiveX){
                toSend["direction"] = "y";
            }
            else{
                toSend["direction"] = "both";
            }
        }
        else {
            return;
        }
        manager.zoom(toSend);
    }

    ValueAxis{
        id: xAxisB
        objectName: "bottom"
        min: 0
        max: 100
    }

    ValueAxis{
        id: yAxisL
        objectName: "left"
        min: 0
        max: 100
    }

    ValueAxis{
        id: xAxisT
        objectName: "top"
        min: 0
        max: 100
    }

    ValueAxis{
        id: yAxisR
        objectName: "right"
        min: 0
        max: 100
    }

    LogValueAxis{
        id: xLogAxisB
        objectName: "logBottom"
        min: 0
        max: 100
    }

    LogValueAxis{
        id: yLogAxisL
        objectName: "logLeft"
        min: 0
        max: 100
    }

    LogValueAxis{
        id: xLogAxisT
        objectName: "logTop"
        min: 0
        max: 100
    }

    LogValueAxis{
        id: yLogAxisR
        objectName: "logRight"
        min: 0
        max: 100
    }

    // FAKE SERIES TO VISUALIZE AXIS CORRECTLY - START
    LineSeries{
        id: bottomNleft
        name: "bottomNleft"
        axisX: xAxisB
        axisY: yAxisL
        visible: false
    }

    LineSeries{
        id: topNright
        name: "topNright"
        axisXTop: xAxisT
        axisYRight: yAxisR
        visible: false
    }

    LineSeries{
        id: bottomNleftLog
        name: "bottomNleftLog"
        axisX: xLogAxisB
        axisY: yLogAxisL
        visible: false
    }

    LineSeries{
        id: topNrightLog
        name: "btopNrightLog"
        axisXTop: xLogAxisT
        axisYRight: yLogAxisR
        visible: false
    }
    // FAKE SERIES TO VISUALIZE AXIS CORRECTLY - END

    MouseArea{
        id: dynamoMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property int oldX: 0
        property int oldY: 0

        onClicked: {
            if (mouse.button == Qt.RightButton)// && manager.interactionEnabled) Commented since it's not compatible with the TestChartMng class
            {
                dynamoMenu.popup();
            }
        }
        onDoubleClicked: {
            manager.resetAxis();
        }
        onPressAndHold: {
            parent.grabPlot();
        }
        onMouseXChanged: {
            if(cursorShape === Qt.ClosedHandCursor){
                var normDelta = (mouseX-oldX)/(parent.plotArea["width"]);
                oldX = mouseX;
                manager.panX({"normDelta":normDelta,"code":panCodeX});
            }
        }
        onMouseYChanged: {
            if(cursorShape === Qt.ClosedHandCursor){
                var normDelta = (mouseY-oldY)/(parent.plotArea["height"]);
                oldY = mouseY;
                manager.panY({"normDelta":normDelta,"code":panCodeY});
            }
        }
        onReleased: {
            cursorShape = Qt.ArrowCursor;
        }
        onWheel: {
            if (wheel.angleDelta.y>0){
                parent.dynamoZoom(1);
            }
            else{
                parent.dynamoZoom(-1);
            }
        }

        function dynamoAutoScale(){
            responsiveX = !autoXMenuItem.checked;
            responsiveY = !autoYMenuItem.checked;
            lxzMenuItem.checked = false;
            lyzMenuItem.checked = false;
            lxrMenuItem.checked = false;
            lyrMenuItem.checked = false;
            var toSend = {"x":autoXMenuItem.checked,"y":autoYMenuItem.checked};
            manager.setAutoScale(toSend);
            if (!(autoXMenuItem.checked || autoYMenuItem.checked)){
                autoMenuItem.text = "Enable autoscale";
            }
            else{
                autoMenuItem.text = "Disable autoscale";
            }
        }
        function dynamoGlobalAutoScale(){
            if (autoMenuItem.text == "Enable autoscale"){
                dynamoMouse.actOnXAuto = false;
                dynamoMouse.actOnYAuto = false;
                autoXMenuItem.checked = true;
                autoYMenuItem.checked = true;
                dynamoMouse.dynamoAutoScale();
                dynamoMouse.actOnXAuto = true;
                dynamoMouse.actOnYAuto = true;
                autoMenuItem.text = "Disable autoscale";
            }
            else{
                dynamoMouse.actOnXAuto = false;
                dynamoMouse.actOnYAuto = false;
                autoXMenuItem.checked = false;
                autoYMenuItem.checked = false;
                dynamoMouse.dynamoAutoScale();
                dynamoMouse.actOnXAuto = true;
                dynamoMouse.actOnYAuto = true;
                autoMenuItem.text = "Enable autoscale";
            }
        }

        Menu {
            id: dynamoMenu
            Material.accent: Material.Orange
            Material.primary: Material.BlueGrey

            Menu {
                id: dynamoAutoMenu
                title: "Autoscale options"

                MenuItem {
                    id: autoMenuItem
                    text: "Enable autoscale"
                    onTriggered: {
                       dynamoMouse.dynamoGlobalAutoScale();
                    }
                }

                MenuSeparator { }

                Menu {
                    id: autoXMenu
                    title: "X axes"

                    MenuItem {
                        id: autoXMenuItem
                        text: "Enable all X"
                        onTriggered: {
                           dynamoMouse.dynamoGlobalAutoScale();
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: autoXBMenuItem
                        text: "Linear X bottom"
                        checkable: true

                    }

                    MenuItem {
                        id: autoXTMenuItem
                        text: "Linear X top"
                        checkable: true

                    }

                    MenuItem {
                        id: autoLogXBMenuItem
                        text: "Log X bottom"
                        checkable: true

                    }

                    MenuItem {
                        id: autoLogXTMenuItem
                        text: "Log X top"
                        checkable: true

                    }
                }

                Menu {
                    id: autoYMenu
                    title: "Y axes"

                    MenuItem {
                        id: autoYMenuItem
                        text: "Enable all Y"
                        onTriggered: {
                           dynamoMouse.dynamoGlobalAutoScale();
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: autoYLMenuItem
                        text: "Linear Y left"
                        checkable: true

                    }

                    MenuItem {
                        id: autoYRMenuItem
                        text: "Linear Y right"
                        checkable: true

                    }

                    MenuItem {
                        id: autoLogYLMenuItem
                        text: "Log Y Left"
                        checkable: true

                    }

                    MenuItem {
                        id: autoLogYRMenuItem
                        text: "Log Y right"
                        checkable: true

                    }
                }
            }

            Menu {
                id: dynamoZoomMenu
                title: "Zoom options"

                MenuItem {
                    id: zoomMenuItem
                    text: "Enable zoom"
                    onTriggered: {
                       dynamoMouse.dynamoGlobalAutoScale();
                    }
                }

                MenuSeparator { }

                Menu {
                    id: zoomXMenu
                    title: "X axes"

                    MenuItem {
                        id: zoomXMenuItem
                        text: "Enable all X"
                        onTriggered: {
                           dynamoMouse.dynamoGlobalAutoScale();
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: zoomXBMenuItem
                        text: "Linear X bottom"
                        checkable: true

                    }

                    MenuItem {
                        id: zoomXTMenuItem
                        text: "Linear X top"
                        checkable: true

                    }

                    MenuItem {
                        id: zoomLogXBMenuItem
                        text: "Log X bottom"
                        checkable: true

                    }

                    MenuItem {
                        id: zoomLogXTMenuItem
                        text: "Log X top"
                        checkable: true

                    }
                }

                Menu {
                    id: zoomYMenu
                    title: "Y axes"

                    MenuItem {
                        id: zoomYMenuItem
                        text: "Enable all Y"
                        onTriggered: {
                           dynamoMouse.dynamoGlobalAutoScale();
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: zoomYLMenuItem
                        text: "Linear Y left"
                        checkable: true

                    }

                    MenuItem {
                        id: zoomYRMenuItem
                        text: "Linear Y right"
                        checkable: true

                    }

                    MenuItem {
                        id: zoomLogYLMenuItem
                        text: "Log Y Left"
                        checkable: true

                    }

                    MenuItem {
                        id: zoomLogYRMenuItem
                        text: "Log Y right"
                        checkable: true

                    }
                }
            }

            Menu {
                id: dynamoPanMenu
                title: "Pan options"

                MenuItem {
                    id: panMenuItem
                    text: "Enable pan"
                    onTriggered: {
                       dynamoMouse.dynamoGlobalAutoScale();
                    }
                }

                MenuSeparator { }

                Menu {
                    id: panXMenu
                    title: "X axes"

                    MenuItem {
                        id: panXMenuItem
                        text: "Enable all X"
                        onTriggered: {
                           dynamoMouse.dynamoGlobalAutoScale();
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: panXBMenuItem
                        text: "Linear X bottom"
                        checkable: true

                    }

                    MenuItem {
                        id: panXTMenuItem
                        text: "Linear X top"
                        checkable: true

                    }

                    MenuItem {
                        id: panLogXBMenuItem
                        text: "Log X bottom"
                        checkable: true

                    }

                    MenuItem {
                        id: panLogXTMenuItem
                        text: "Log X top"
                        checkable: true

                    }
                }

                Menu {
                    id: panYMenu
                    title: "Y axes"

                    MenuItem {
                        id: panYLMenuItem
                        text: "Linear Y left"
                        checkable: true

                    }

                    MenuItem {
                        id: panYRMenuItem
                        text: "Linear Y right"
                        checkable: true

                    }

                    MenuItem {
                        id: panLogYLMenuItem
                        text: "Log Y Left"
                        checkable: true

                    }

                    MenuItem {
                        id: panLogYRMenuItem
                        text: "Log Y right"
                        checkable: true

                    }
                }
            }

            MenuSeparator { }

            MenuItem {
                id: fixValMenuItem
                text: "Set as default zoom"

                onTriggered: {
                    manager.fixAxis();
                }
            }
        }
    }
}
