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
    property int zoomCodeX: 0
    property int zoomCodeY: 0
    property int panCodeX: 0
    property int panCodeY: 0
    states: [
        State {
            name: "empty"
        },
        State {
            name: "plotting"
        },
        State {
            name: "measuring"
        },
        State {
            name: "filled"
        }
    ]

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
        seriesNum++;
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
        }
        onMouseYChanged: {
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

                MenuItem {
                    id: autoXMenuItem
                    text: "Autoscale for X"
                    checkable: true
                    onCheckedChanged: {
                        if (dynamoMouse.actOnXAuto){
                            dynamoMouse.dynamoAutoScale()
                        }
                    }
                }

                MenuItem {
                    id: autoYMenuItem
                    text: "Autoscale for Y"
                    checkable: true
                    onCheckedChanged: {
                        if (dynamoMouse.actOnYAuto){
                            dynamoMouse.dynamoAutoScale()
                        }
                    }
                }
            }

            Menu {
                id: dynamoZoomMenu
                title: "Zoom options"

                MenuItem {
                    id: lxzMenuItem
                    text: "Zoom only on X"
                    checkable: true
                    visible: dynamoMouse.responsiveX
                }

                MenuItem {
                    id: lyzMenuItem
                    text: "Zoom only on Y"
                    checkable: true
                    visible: dynamoMouse.responsiveY
                }
            }

            Menu {
                id: dynamoTransMenu
                title: "Translation options"

                MenuItem {
                    id: lxrMenuItem
                    text: "Move only on X"
                    checkable: true
                    visible: dynamoMouse.responsiveX
                }

                MenuItem {
                    id: lyrMenuItem
                    text: "Move only on Y"
                    checkable: true
                    visible: dynamoMouse.responsiveY
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
