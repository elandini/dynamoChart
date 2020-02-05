import QtQuick 2.0
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.3
import QtCharts 2.3

ChartView{
    focus: true
    property var manager
    property var currentSeries: {[]}
    // codes are numbers going from 0 to 1111. They are formed this way:
    //
    states: [
        State {
            name: "empty" //This state is used when the plot is empty. It has no series
            PropertyChanges { target: dynamoMouse; menuEnabled: false }
        },
        State {
            name: "initialized" //This state is used when the plot is empty. It has series but they are empty
            PropertyChanges { target: dynamoMouse; menuEnabled: true }
        },
        State {
            name: "measuring" // This is the state to be used when new points are fed to the plot
            PropertyChanges { target: dynamoMouse; menuEnabled: false }
        },
        State {
            name: "filled" // This state has to be used when the plot has been filled and no other point is going to be added
            PropertyChanges { target: dynamoMouse; menuEnabled: true }
        }
    ]

    // Sets the chart state
    function setState(newState){
        state = newState;
    }
    // Adds a series to the chart
    // @param params Dictionary:
    function addNewSeries(params){
        console.log(JSON.stringify(params));
        var newSeries; // = createSeries(type,name);
        var theX;
        var theY;
        switch(params.plotType){
            case "linlin":
                theX = params.bottom ? xAxisB : xAxisT;
                theY = params.left ? yAxisL : yAxisR;
                yAxisL.present = params.left;
                yAxisR.present = !params.left;
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
        axesPresence(theX,theY);
        newSeries = createSeries(params.type,params.name,theX,theY);
        newSeries.pointsVisible = params.points;
        newSeries.color = params.color;
        var toSend = params;
        params.series = newSeries;
        manager.registerSeries(params);
        currentSeries.push(params.name);
        if (state === "empty"){
            setState("initialized");
        }

        return newSeries
    }
    function axisPresence(toSet,inputAxis){
        if(!toSet.present){
            toSet.present = inputAxis === toSet;
        }
    }
    function axesPresence(inputX,inputY){
        axisPresence(xAxisB,inputX);
        axisPresence(xAxisT,inputX);
        axisPresence(xLogAxisB,inputX);
        axisPresence(xLogAxisT,inputX);
        axisPresence(yAxisL,inputY);
        axisPresence(yAxisR,inputY);
        axisPresence(yLogAxisL,inputY);
        axisPresence(yLogAxisR,inputY);
    }
    function addMultipleSeries(seriesContainer){
        for(var s in seriesContainer["seriesList"]){
            addNewSeries(seriesContainer["seriesList"][s]);
        }
    }
    function managerAssociation(){
        manager.xBottom = xAxisB;
        manager.yLeft = yAxisL;
        manager.xTop = xAxisT;
        manager.yRight = yAxisR;

        manager.xLogBottom = xLogAxisB;
        manager.yLogLeft = yLogAxisL;
        manager.xLogTop = xLogAxisT;
        manager.yLogRight = yLogAxisR;

        manager.axisAssigned = true;
        manager.addingSeries.connect(addNewSeries);
    }
    function smartClear(){
        manager.clear();
        for (var s in currentSeries){
            var toRemove = series(currentSeries[s]);
            removeSeries(toRemove);
        }
        xAxisB.present = false;
        xAxisT.present = false;
        xLogAxisB.present = false;
        xLogAxisT.present = false;
        yAxisL.present = false;
        yAxisR.present = false;
        yLogAxisL.present = false;
        yLogAxisR.present = false;
    }

    ValueAxis{
        id: xAxisB
        objectName: "bottom"
        min: 0
        max: 100
        visible: present
        property bool present: false
    }

    ValueAxis{
        id: yAxisL
        objectName: "left"
        min: 0
        max: 100
        visible: present
        property bool present: false
    }

    ValueAxis{
        id: xAxisT
        objectName: "top"
        min: 0
        max: 100
        visible: present
        property bool present: false
    }

    ValueAxis{
        id: yAxisR
        objectName: "right"
        min: 0
        max: 100
        visible: present
        property bool present: false
    }

    LogValueAxis{
        id: xLogAxisB
        objectName: "logBottom"
        min: 0
        max: 100
        visible: present
        property bool present: false
    }

    LogValueAxis{
        id: yLogAxisL
        objectName: "logLeft"
        min: 0
        max: 100
        visible: present
        property bool present: false
    }

    LogValueAxis{
        id: xLogAxisT
        objectName: "logTop"
        min: 0
        max: 100
        visible: present
        property bool present: false
    }

    LogValueAxis{
        id: yLogAxisR
        objectName: "logRight"
        min: 0
        max: 100
        visible: present
        property bool present: false
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
        property bool menuEnabled: false
        property int oldX: 0
        property int oldY: 0

        onClicked: {
            if (mouse.button == Qt.RightButton && manager.interactionEnabled && dynamoMouse.menuEnabled) //Commented since it's not compatible with the TestChartMng class
            {
                dynamoMenu.popup();
            }
        }
        onDoubleClicked: {
            manager.resetAllAxis();
        }
        onPressAndHold: {
            grabPlot();
        }
        onMouseXChanged: {
            if(cursorShape === Qt.ClosedHandCursor){
                var normDelta = (mouseX-oldX)/(parent.plotArea["width"]);
                oldX = mouseX;
                manager.panX({"normDelta":normDelta});
            }
        }
        onMouseYChanged: {
            if(cursorShape === Qt.ClosedHandCursor){
                var normDelta = (mouseY-oldY)/(parent.plotArea["height"]);
                oldY = mouseY;
                manager.panY({"normDelta":normDelta});
            }
        }
        onReleased: {
            cursorShape = Qt.ArrowCursor;
        }
        onWheel: {
            if (wheel.angleDelta.y>0){
                dynamoZoom(1);
            }
            else{
                dynamoZoom(-1);
            }
        }
        function grabPlot(){
            if (dynamoMouse.menuEnabled && manager.interactionEnabled){
                cursorShape = Qt.ClosedHandCursor;
                dynamoMouse.oldX = dynamoMouse.mouseX;
                dynamoMouse.oldY = dynamoMouse.mouseY;
            }
        }
        function dynamoZoom(verse){
            if (dynamoMouse.menuEnabled && manager.interactionEnabled){
                var toSend = {"verse": verse};
                manager.zoom(toSend);
            }
        }

        Menu {
            id: dynamoMenu
            Material.accent: Material.Orange
            Material.primary: Material.BlueGrey
            property bool singleAutoTrigger: true
            property bool singlePanTrigger: true
            property bool singleZoomTrigger: true

            function allAutoTriggers(value){
                singleAutoTrigger = false;
                autoMenuItem.text = value ? "Disable autoscale" : "Enable autoscale";
                autoXMenuItem.text = value ? "Disable all X" : "Enable all X";
                autoYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                autoLogXBMenuItem.checked = value;
                autoLogXTMenuItem.checked = value;
                autoXBMenuItem.checked = value;
                autoXTMenuItem.checked = value;
                autoLogYLMenuItem.checked = value;
                autoLogYRMenuItem.checked = value;
                autoYLMenuItem.checked = value;
                autoYRMenuItem.checked = value;

                sendAutoTriggers();
                singleAutoTrigger = true;
            }
            function allXAutoTriggers(value){
                singleAutoTrigger = false;
                autoXMenuItem.text = value ? "Disable all X" : "Enable all X";
                autoLogXBMenuItem.checked = value;
                autoLogXTMenuItem.checked = value;
                autoXBMenuItem.checked = value;
                autoXTMenuItem.checked = value;

                sendAutoTriggers();
                singleAutoTrigger = true;
            }
            function allYAutoTriggers(value){
                singleAutoTrigger = false;
                autoYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                autoLogYLMenuItem.checked = value;
                autoLogYRMenuItem.checked = value;
                autoYLMenuItem.checked = value;
                autoYRMenuItem.checked = value;

                sendAutoTriggers();
                singleAutoTrigger = true;
            }
            function sendAutoTriggers(){
                var toSend = {"x":{},"y":{}};
                toSend["x"][xAxisB.objectName] = autoXBMenuItem.checked;
                toSend["x"][xAxisT.objectName] = autoXTMenuItem.checked;
                toSend["x"][xLogAxisB.objectName] = autoLogXBMenuItem.checked;
                toSend["x"][xLogAxisT.objectName] = autoLogXTMenuItem.checked;
                toSend["y"][yAxisL.objectName] = autoYLMenuItem.checked;
                toSend["y"][yAxisR.objectName] = autoYRMenuItem.checked;
                toSend["y"][yLogAxisL.objectName] = autoLogYLMenuItem.checked;
                toSend["y"][yLogAxisR.objectName] = autoLogYRMenuItem.checked;

                manager.setAutoScale(toSend);
            }
            function allZoomTriggers(value){
                singleZoomTrigger = false;
                zoomMenuItem.text = value ? "Disable zoom" : "Enable zoom";
                zoomXMenuItem.text = value ? "Disable all X" : "Enable all X";
                zoomYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                zoomLogXBMenuItem.checked = value;
                zoomLogXTMenuItem.checked = value;
                zoomXBMenuItem.checked = value;
                zoomXTMenuItem.checked = value;
                zoomLogYLMenuItem.checked = value;
                zoomLogYRMenuItem.checked = value;
                zoomYLMenuItem.checked = value;
                zoomYRMenuItem.checked = value;

                sendZoomTriggers();
                singleZoomTrigger = true;
            }
            function allXZoomTriggers(value){
                singleZoomTrigger = false;
                zoomXMenuItem.text = value ? "Disable all X" : "Enable all X";
                zoomLogXBMenuItem.checked = value;
                zoomLogXTMenuItem.checked = value;
                zoomXBMenuItem.checked = value;
                zoomXTMenuItem.checked = value;

                sendZoomTriggers();
                singleZoomTrigger = true;
            }
            function allYZoomTriggers(value){
                singleZoomTrigger = false;
                zoomYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                zoomLogYLMenuItem.checked = value;
                zoomLogYRMenuItem.checked = value;
                zoomYLMenuItem.checked = value;
                zoomYRMenuItem.checked = value;

                sendZoomTriggers();
                singleZoomTrigger = true;
            }
            function sendZoomTriggers(){
                var toSend = {"x":{},"y":{}};
                toSend["x"][xAxisB.objectName] = zoomXBMenuItem.checked;
                toSend["x"][xAxisT.objectName] = zoomXTMenuItem.checked;
                toSend["x"][xLogAxisB.objectName] = zoomLogXBMenuItem.checked;
                toSend["x"][xLogAxisT.objectName] = zoomLogXTMenuItem.checked;
                toSend["y"][yAxisL.objectName] = zoomYLMenuItem.checked;
                toSend["y"][yAxisR.objectName] = zoomYRMenuItem.checked;
                toSend["y"][yLogAxisL.objectName] = zoomLogYLMenuItem.checked;
                toSend["y"][yLogAxisR.objectName] = zoomLogYRMenuItem.checked;

                manager.setZoomAllowed(toSend);
            }
            function allPanTriggers(value){
                singlePanTrigger = false;
                panMenuItem.text = value ? "Disable pan" : "Enable pan";
                panXMenuItem.text = value ? "Disable all X" : "Enable all X";
                panYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                panLogXBMenuItem.checked = value;
                panLogXTMenuItem.checked = value;
                panXBMenuItem.checked = value;
                panXTMenuItem.checked = value;
                panLogYLMenuItem.checked = value;
                panLogYRMenuItem.checked = value;
                panYLMenuItem.checked = value;
                panYRMenuItem.checked = value;

                sendPanTriggers();
                singlePanTrigger = true;
            }
            function allXPanTriggers(value){
                singlePanTrigger = false;
                panXMenuItem.text = value ? "Disable all X" : "Enable all X";
                panLogXBMenuItem.checked = value;
                panLogXTMenuItem.checked = value;
                panXBMenuItem.checked = value;
                panXTMenuItem.checked = value;

                sendPanTriggers();
                singlePanTrigger = true;
            }
            function allYPanTriggers(value){
                singlePanTrigger = false;
                panYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                panLogYLMenuItem.checked = value;
                panLogYRMenuItem.checked = value;
                panYLMenuItem.checked = value;
                panYRMenuItem.checked = value;

                sendPanTriggers();
                singlePanTrigger = true;
            }
            function sendPanTriggers(){
                var toSend = {"x":{},"y":{}};
                toSend["x"][xAxisB.objectName] = panXBMenuItem.checked;
                toSend["x"][xAxisT.objectName] = panXTMenuItem.checked;
                toSend["x"][xLogAxisB.objectName] = panLogXBMenuItem.checked;
                toSend["x"][xLogAxisT.objectName] = panLogXTMenuItem.checked;
                toSend["y"][yAxisL.objectName] = panYLMenuItem.checked;
                toSend["y"][yAxisR.objectName] = panYRMenuItem.checked;
                toSend["y"][yLogAxisL.objectName] = panLogYLMenuItem.checked;
                toSend["y"][yLogAxisR.objectName] = panLogYRMenuItem.checked;

                manager.setPanAllowed(toSend);
            }

            Menu {
                id: dynamoAutoMenu
                title: "Autoscale options"

                MenuItem {
                    id: autoMenuItem
                    text: "Enable autoscale"
                    onTriggered: {
                        dynamoMenu.allAutoTriggers(autoMenuItem.text === "Enable autoscale");
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
                            dynamoMenu.allXAutoTriggers(autoXMenuItem.text === "Enable all X");
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: autoXBMenuItem
                        text: "Linear X bottom"
                        checkable: true
                        checked: false
                        enabled: xAxisB.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleAutoTrigger){
                                dynamoMenu.sendAutoTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: autoXTMenuItem
                        text: "Linear X top"
                        checkable: true
                        checked: false
                        enabled: xAxisT.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleAutoTrigger){
                                dynamoMenu.sendAutoTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: autoLogXBMenuItem
                        text: "Log X bottom"
                        checkable: true
                        checked: false
                        enabled: xLogAxisB.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleAutoTrigger){
                                dynamoMenu.sendAutoTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: autoLogXTMenuItem
                        text: "Log X top"
                        checkable: true
                        checked: false
                        enabled: xLogAxisT.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleAutoTrigger){
                                dynamoMenu.sendAutoTriggers();
                            }
                        }
                    }
                }

                Menu {
                    id: autoYMenu
                    title: "Y axes"

                    MenuItem {
                        id: autoYMenuItem
                        text: "Enable all Y"
                        onTriggered: {
                           dynamoMenu.allYAutoTriggers(autoYMenuItem.text === "Enable all Y");
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: autoYLMenuItem
                        text: "Linear Y left"
                        checkable: true
                        checked: false
                        enabled: yAxisL.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleAutoTrigger){
                                dynamoMenu.sendAutoTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: autoYRMenuItem
                        text: "Linear Y right"
                        checkable: true
                        checked: false
                        enabled: yAxisR.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleAutoTrigger){
                                dynamoMenu.sendAutoTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: autoLogYLMenuItem
                        text: "Log Y Left"
                        checkable: true
                        checked: false
                        enabled: yLogAxisL.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleAutoTrigger){
                                dynamoMenu.sendAutoTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: autoLogYRMenuItem
                        text: "Log Y right"
                        checkable: true
                        checked: false
                        enabled: yLogAxisR.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleAutoTrigger){
                                dynamoMenu.sendAutoTriggers();
                            }
                        }
                    }
                }
            }

            Menu {
                id: dynamoZoomMenu
                title: "Zoom options"

                MenuItem {
                    id: zoomMenuItem
                    text: "Disable zoom"
                    onTriggered: {
                       dynamoMenu.allZoomTriggers(zoomMenuItem.text === "Enable zoom");
                    }
                }

                MenuSeparator { }

                Menu {
                    id: zoomXMenu
                    title: "X axes"

                    MenuItem {
                        id: zoomXMenuItem
                        text: "Disable all X"
                        onTriggered: {
                           dynamoMenu.allXZoomTriggers(zoomXMenuItem.text === "Enable all X")
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: zoomXBMenuItem
                        text: "Linear X bottom"
                        checkable: true
                        checked: true
                        enabled: xAxisB.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleZoomTrigger){
                                dynamoMenu.sendZoomTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: zoomXTMenuItem
                        text: "Linear X top"
                        checkable: true
                        checked: true
                        enabled: xAxisT.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleZoomTrigger){
                                dynamoMenu.sendZoomTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: zoomLogXBMenuItem
                        text: "Log X bottom"
                        checkable: true
                        checked: true
                        enabled: xLogAxisB.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleZoomTrigger){
                                dynamoMenu.sendZoomTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: zoomLogXTMenuItem
                        text: "Log X top"
                        checkable: true
                        checked: true
                        enabled: xLogAxisT.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleZoomTrigger){
                                dynamoMenu.sendZoomTriggers();
                            }
                        }
                    }
                }

                Menu {
                    id: zoomYMenu
                    title: "Y axes"

                    MenuItem {
                        id: zoomYMenuItem
                        text: "Disable all Y"
                        onTriggered: {
                           dynamoMenu.allYZoomTriggers(zoomYMenuItem.text === "Enable all Y")
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: zoomYLMenuItem
                        text: "Linear Y left"
                        checkable: true
                        checked: true
                        enabled: yAxisL.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleZoomTrigger){
                                dynamoMenu.sendZoomTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: zoomYRMenuItem
                        text: "Linear Y right"
                        checkable: true
                        checked: true
                        enabled: yAxisR.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleZoomTrigger){
                                dynamoMenu.sendZoomTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: zoomLogYLMenuItem
                        text: "Log Y Left"
                        checkable: true
                        checked: true
                        enabled: yLogAxisL.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleZoomTrigger){
                                dynamoMenu.sendZoomTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: zoomLogYRMenuItem
                        text: "Log Y right"
                        checkable: true
                        checked: true
                        enabled: yLogAxisR.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singleZoomTrigger){
                                dynamoMenu.sendZoomTriggers();
                            }
                        }
                    }
                }
            }

            Menu {
                id: dynamoPanMenu
                title: "Pan options"

                MenuItem {
                    id: panMenuItem
                    text: "Disable pan"
                    onTriggered: {
                       dynamoMenu.allPanTriggers(panMenuItem.text === "Enable pan");
                    }
                }

                MenuSeparator { }

                Menu {
                    id: panXMenu
                    title: "X axes"

                    MenuItem {
                        id: panXMenuItem
                        text: "Disable all X"
                        onTriggered: {
                           dynamoMenu.allXPanTriggers(panXMenuItem.text === "Enable all X");
                        }
                    }

                    MenuSeparator { }

                    MenuItem {
                        id: panXBMenuItem
                        text: "Linear X bottom"
                        checkable: true
                        checked: true
                        enabled: xAxisB.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singlePanTrigger){
                                dynamoMenu.sendPanTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: panXTMenuItem
                        text: "Linear X top"
                        checkable: true
                        checked: true
                        enabled: xAxisT.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singlePanTrigger){
                                dynamoMenu.sendPanTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: panLogXBMenuItem
                        text: "Log X bottom"
                        checkable: true
                        checked: true
                        enabled: xLogAxisB.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singlePanTrigger){
                                dynamoMenu.sendPanTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: panLogXTMenuItem
                        text: "Log X top"
                        checkable: true
                        checked: true
                        enabled: xLogAxisT.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singlePanTrigger){
                                dynamoMenu.sendPanTriggers();
                            }
                        }
                    }
                }

                Menu {
                    id: panYMenu
                    title: "Y axes"

                    MenuItem {
                        id: panYMenuItem
                        text: "Disable all Y"
                        onTriggered: {
                           dynamoMenu.allYPanTriggers(panYMenuItem.text === "Enable all Y");
                        }
                    }

                    MenuItem {
                        id: panYLMenuItem
                        text: "Linear Y left"
                        checkable: true
                        checked: true
                        enabled: yAxisL.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singlePanTrigger){
                                dynamoMenu.sendPanTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: panYRMenuItem
                        text: "Linear Y right"
                        checkable: true
                        checked: true
                        enabled: yAxisR.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singlePanTrigger){
                                dynamoMenu.sendPanTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: panLogYLMenuItem
                        text: "Log Y Left"
                        checkable: true
                        checked: true
                        enabled: yLogAxisL.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singlePanTrigger){
                                dynamoMenu.sendPanTriggers();
                            }
                        }
                    }

                    MenuItem {
                        id: panLogYRMenuItem
                        text: "Log Y right"
                        checkable: true
                        checked: true
                        enabled: yLogAxisR.present
                        onCheckedChanged: function(){
                            if (dynamoMenu.singlePanTrigger){
                                dynamoMenu.sendPanTriggers();
                            }
                        }
                    }
                }
            }

            MenuSeparator { }

            MenuItem {
                id: fixValMenuItem
                text: "Set as default zoom"

                onTriggered: {
                    manager.fixAllAxes();
                }
            }
        }
    }
}
