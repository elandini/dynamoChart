import QtQuick 2.0
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.3
import QtCharts 2.3

ChartView{ // This element is the QML side of the "DynamoChart library".
           // It has to be used in combination with a DynamoChartManager object (or a derived one) on the python side
    focus: true
    property string xBName: "bottom"
    property string xTName: "top"
    property string logXBName: "logBottom"
    property string logXTName: "logTop"
    property string yLName: "left"
    property string yRName: "right"
    property string logYLName: "logLeft"
    property string logYRName: "logRight"
    property var manager  // This is the DynamoChartManager object associated with the QML chart.
                          // The value of this property has to be assigned before allowing the user
                          // to interact with the QML chart.
    property var currentSeries: {[]}

    /// <summary>
    /// Adds a series to the chart
    /// </summary>
    /// <param name="params">Dictionary: It contains all the information needed to create a new series on the QML side</param>
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
        if(!theX.visible){
            theX.visible = true;
        }
        if(!theY.visible){
            theY.visible = true;
        }
        newSeries = createSeries(params.type,params.name,theX,theY);
        newSeries.pointsVisible = params.points;
        newSeries.color = params.color;
        newSeries.markerSize = params.markerSize;
        params.series = newSeries;  // The actual series object has to be created here and
                                    // than send to the manager that will manage it because
                                    // that's the only way I found to get everything to work
                                    // as expected.
        manager.registerSeries(params);
        currentSeries.push(params.name);

        return newSeries
    }
    /// <summary>
    /// It can be used to add multiple series to theChartView
    /// </summary>
    /// <param name="seriesContainer">Dictionary: It contains a dictionary for each new series to add</param>
    function addMultipleSeries(seriesContainer){
        for(var s in seriesContainer["seriesList"]){
            addNewSeries(seriesContainer["seriesList"][s]);
        }
    }
    /// <summary>
    /// Initializes all the connections needed to correctly communicate with the manager object
    /// This function has to be called before allowing the user to interact with the ChartView
    /// </summary>
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
        manager.addingSeries.connect(addNewSeries);  // The series have to be added via manager object.
                                                     // When a new series has to be added, a dictionary with the
                                                     // series features is send to the manager object on python side.
                                                     // The manager then emits the "addingSeries" signal which brings
                                                     // the aforementioned dictionary with it.
                                                     // The signal triggers the "addNewSeries" slot that creates the QML
                                                     // "series" object, puts it in the input dictionary and sends
                                                     // everything back to the python side manager.
        manager.cleared.connect(smartClear);
    }
    /// <summary>
    /// This function intercepts the "cleared" signal from the manager, removes all the series from the ChartView
    /// empties the "currentSeries" list and hides all the axis
    /// </summary>
    function smartClear(){
        for (var s in currentSeries){
            var toRemove = series(currentSeries[s]);
            removeSeries(toRemove);
        }
        xAxisB.visible = false;
        xAxisT.visible = false;
        xLogAxisB.visible = false;
        xLogAxisT.visible = false;
        yAxisL.visible = false;
        yAxisR.visible = false;
        yLogAxisL.visible = false;
        yLogAxisR.visible = false;
        currentSeries = [];
    }
    /// <summary>
    /// Allows to enable or disable autoscaling on all the axes without interacting with the popup menu
    /// </summary>
    /// <param name="value">Boolean: The value that will determine the enabling/disabling of the autoscale on all the axes</param>
    function switchRemoteAutoscale(value){
        dynamoMenu.allAutoTriggers(value);
    }

    ValueAxis{
        id: xAxisB
        objectName: "bottom"
        min: 0
        max: 100
        visible: false
    }

    ValueAxis{
        id: yAxisL
        objectName: "left"
        min: 0
        max: 100
        visible: false
    }

    ValueAxis{
        id: xAxisT
        objectName: "top"
        min: 0
        max: 100
        visible: false
    }

    ValueAxis{
        id: yAxisR
        objectName: "right"
        min: 0
        max: 100
        visible: false
    }

    LogValueAxis{
        id: xLogAxisB
        objectName: "logBottom"
        min: 0
        max: 100
        visible: false
    }

    LogValueAxis{
        id: yLogAxisL
        objectName: "logLeft"
        min: 0
        max: 100
        visible: false
    }

    LogValueAxis{
        id: xLogAxisT
        objectName: "logTop"
        min: 0
        max: 100
        visible: false
    }

    LogValueAxis{
        id: yLogAxisR
        objectName: "logRight"
        min: 0
        max: 100
        visible: false
    }

    // FAKE SERIES TO VISUALIZE AXIS CORRECTLY - START
    // This series are needed because if the axes are not explicitely used in a QML AbstractSeries object
    // as "left", "right", "bottom", or "up", if you create series dynamically, they will appear in the
    // wrong position (mainly the right and the up axes will just be addictional left and bottom axis)
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
        property bool menuEnabled: true
        property int oldX: 0
        property int oldY: 0

        // Mouse events connections ----------------------- START //
        onClicked: {
            if (mouse.button === Qt.RightButton && manager.interactionEnabled && dynamoMouse.menuEnabled)
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
                var normDelta = (oldX-mouseX)/(parent.plotArea["width"]);
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
        // Mouse events connections ------------------------- END //
        /// <summary>
        /// It is called when the left mouse button is pressed and held. It changes the shape of the cursor
        /// and saves the cursors current position. From this moment, and untill the mouse button is released,
        /// the pan action will be performed on all the axes that allows that
        /// </summary>
        function grabPlot(){
            if (dynamoMouse.menuEnabled && manager.interactionEnabled){
                cursorShape = Qt.ClosedHandCursor;
                dynamoMouse.oldX = dynamoMouse.mouseX;
                dynamoMouse.oldY = dynamoMouse.mouseY;
            }
        }
        /// <summary>
        /// It calls the manager zoom function with a specific verse.
        /// The verse can be:
        ///     - 1: Zoom in
        ///     - -1: Zoom out
        /// </summary>
        /// <param name="verse">Integer: It represent the zooming verse</param>
        function dynamoZoom(verse){
            if (dynamoMouse.menuEnabled && manager.interactionEnabled){
                var toSend = {"verse": verse};
                manager.zoom(toSend);
            }
        }

        Menu { // This menu manages the interactions between the user and the ChartView
            id: dynamoMenu
            Material.accent: Material.Orange
            Material.primary: Material.BlueGrey
            // The following three boolean properties are used to avoid triggering
            // the "checked change" event for each individual menu items when an all"BLANK"Triggers
            // function is called (e.g. allAutoTriggers, allPanTriggers, allZoomTriggers, etc).
            property bool singleAutoTrigger: true
            property bool singlePanTrigger: true
            property bool singleZoomTrigger: true
            // The following three boolean properties are used to manage the interactions between
            // the different actions allowed by the menu.
            // First the ratio behind these interactions has to be understood:
            //     1) Enabling autoscale for one axis (or any combination of them) disables zoom and pan for
            //        the same axis (or the ame combination)
            //     2) Disabling autoscale for one axis (or any combination of them) enables zoom and pan for
            //        the same axis (or the ame combination)
            //     3) Enabling pan for one axis (or any combination of them) disables autoscale for
            //        the same axis (or the ame combination)
            //     4) Enabling zoom for one axis (or any combination of them) disables autoscale for
            //        the same axis (or the ame combination)
            // So, 2 can lead to 3 and 4 at the same time. This can lead back to 2 and so on.
            // To avoid this, everytime one of the four aforementioned cases occurs, the correspondent property
            // is set to true and that prevents the triggered actions to start the loop
            property bool autoDerived: false  // It is set to true when autoscale is enabled/disabled by the user
            property bool zoomDerived: false // It is set to true when zooming is enabled by the user
            property bool panDerived: false // It is set to true when panning is enabled by the user

            /// <summary>
            ///
            /// </summary>
            /// <param name=""></param>
            /// <param name=""></param>
            /// <param name=""></param>
            /// <results></results>

            /// <summary>
            /// It sets all the autoscale menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the autoscale</param>
            function allAutoTriggers(value){
                singleAutoTrigger = false;  // Single autoscale-related menu items must not react
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

                zoomMenuItem.text = !value ? "Disable zoom" : "Enable zoom";
                zoomXMenuItem.text = !value ? "Disable all X" : "Enable all X";
                zoomYMenuItem.text = !value ? "Disable all Y" : "Enable all Y";
                panMenuItem.text = !value ? "Disable pan" : "Enable pan";
                panXMenuItem.text = !value ? "Disable all X" : "Enable all X";
                panYMenuItem.text = !value ? "Disable all Y" : "Enable all Y";

                singleAutoTrigger = true; // Single autoscale-related menu items can react again
            }
            /// <summary>
            /// It sets the X axes autoscale menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the autoscale</param>
            function allXAutoTriggers(value){
                singleAutoTrigger = false;
                autoXMenuItem.text = value ? "Disable all X" : "Enable all X";
                autoLogXBMenuItem.checked = value;
                autoLogXTMenuItem.checked = value;
                autoXBMenuItem.checked = value;
                autoXTMenuItem.checked = value;

                sendAutoTriggers();

                zoomXMenuItem.text = !value ? "Disable all X" : "Enable all X";
                panXMenuItem.text = !value ? "Disable all X" : "Enable all X";

                singleAutoTrigger = true;
            }
            /// <summary>
            /// It sets the Y axes autoscale menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the autoscale</param>
            function allYAutoTriggers(value){
                singleAutoTrigger = false;
                autoYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                autoLogYLMenuItem.checked = value;
                autoLogYRMenuItem.checked = value;
                autoYLMenuItem.checked = value;
                autoYRMenuItem.checked = value;

                sendAutoTriggers();
                zoomYMenuItem.text = !value ? "Disable all Y" : "Enable all Y";
                panYMenuItem.text = !value ? "Disable all Y" : "Enable all Y";
                singleAutoTrigger = true;
            }
            /// <summary>
            /// It checks whether or not all the X and Y enabled autoscale menu items
            /// are checked
            /// </summary>
            /// <results>
            /// List: It contains two boolean values, one for X and one for Y, that are true
            /// only if all the enabled menu items for that axis are checked
            /// </results>
            function checkAutoEnabled(){
                var xOk = true;
                var yOk = true;

                xOk = autoXBMenuItem.enabled ? xOk && autoXBMenuItem.checked : xOk;
                xOk = autoXTMenuItem.enabled ? xOk && autoXTMenuItem.checked : xOk;
                xOk = autoLogXBMenuItem.enabled ? xOk && autoLogXBMenuItem.checked : xOk;
                xOk = autoLogXTMenuItem.enabled ? xOk && autoLogXTMenuItem.checked : xOk;
                yOk = autoYLMenuItem.enabled ? yOk && autoYLMenuItem.checked : yOk;
                yOk = autoYRMenuItem.enabled ? yOk && autoYRMenuItem.checked : yOk;
                yOk = autoLogYLMenuItem.enabled ? yOk && autoLogYLMenuItem.checked : yOk;
                yOk = autoLogYRMenuItem.enabled ? yOk && autoLogYRMenuItem.checked : yOk;

                return [xOk,yOk];
            }
            /// <summary>
            /// Sends the values of the autoscale menu items to the manager and, if needed,
            /// modify the zoom and pan menu items
            /// </summary>
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

                var checks = checkAutoEnabled();

                autoMenuItem.text = checks[0]&&checks[1] ? "Disable autoscale" : "Enable autoscale";
                autoXMenuItem.text = checks[0] ? "Disable all X" : "Enable all X";
                autoYMenuItem.text = checks[1] ? "Disable all Y" : "Enable all Y";

                manager.setAutoScale(toSend);
                if(!panDerived && !zoomDerived) autoTriggerToOther(); // If this action hasn't been triggered by zoom or pan, then
                                                                      // it has to influence the values of the zoom and pan menu
                                                                      // items
            }
            /// <summary>
            /// Modify zoom and pan menu items accordingly to the autoscale menu items state
            /// </summary>
            function autoTriggerToOther(){
                autoDerived = true;
                singlePanTrigger = false;
                singleZoomTrigger = false;
                panXBMenuItem.checked = !autoXBMenuItem.checked;
                panXTMenuItem.checked = !autoXTMenuItem.checked;
                panLogXBMenuItem.checked = !autoLogXBMenuItem.checked;
                panLogXTMenuItem.checked = !autoLogXTMenuItem.checked;
                panYLMenuItem.checked = !autoYLMenuItem.checked;
                panYRMenuItem.checked = !autoYRMenuItem.checked;
                panLogYLMenuItem.checked = !autoLogYLMenuItem.checked;
                panLogYRMenuItem.checked = !autoLogYRMenuItem.checked;
                zoomXBMenuItem.checked = !autoXBMenuItem.checked;
                zoomXTMenuItem.checked = !autoXTMenuItem.checked;
                zoomLogXBMenuItem.checked = !autoLogXBMenuItem.checked;
                zoomLogXTMenuItem.checked = !autoLogXTMenuItem.checked;
                zoomYLMenuItem.checked = !autoYLMenuItem.checked;
                zoomYRMenuItem.checked = !autoYRMenuItem.checked;
                zoomLogYLMenuItem.checked = !autoLogYLMenuItem.checked;
                zoomLogYRMenuItem.checked = !autoLogYRMenuItem.checked;
                sendZoomTriggers();
                sendPanTriggers();
                singlePanTrigger = true;
                singleZoomTrigger = true;
                autoDerived = false;
            }
            /// <summary>
            /// It sets all the zoom menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the zoom</param>
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
                autoMenuItem.text = !value ? "Disable autoscale" : "Enable autoscale";
                autoXMenuItem.text = !value ? "Disable all X" : "Enable all X";
                autoYMenuItem.text = !value ? "Disable all Y" : "Enable all Y";
                singleZoomTrigger = true;
            }
            /// <summary>
            /// It sets the X axes zoom menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the zoom</param>
            function allXZoomTriggers(value){
                singleZoomTrigger = false;
                zoomXMenuItem.text = value ? "Disable all X" : "Enable all X";
                zoomLogXBMenuItem.checked = value;
                zoomLogXTMenuItem.checked = value;
                zoomXBMenuItem.checked = value;
                zoomXTMenuItem.checked = value;

                sendZoomTriggers();
                autoXMenuItem.text = !value ? "Disable all X" : "Enable all X";
                singleZoomTrigger = true;
            }
            /// <summary>
            /// It sets the Y axes zoom menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the zoom</param>
            function allYZoomTriggers(value){
                singleZoomTrigger = false;
                zoomYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                zoomLogYLMenuItem.checked = value;
                zoomLogYRMenuItem.checked = value;
                zoomYLMenuItem.checked = value;
                zoomYRMenuItem.checked = value;

                sendZoomTriggers();
                autoYMenuItem.text = !value ? "Disable all Y" : "Enable all Y";
                singleZoomTrigger = true;
            }
            /// <summary>
            /// It checks whether or not all the X and Y enabled zoom menu items
            /// are checked
            /// </summary>
            /// <results>
            /// List: It contains two boolean values, one for X and one for Y, that are true
            /// only if all the enabled menu items for that axis are checked
            /// </results>
            function checkZoomEnabled(){
                var xOk = true;
                var yOk = true;

                xOk = zoomXBMenuItem.enabled ? xOk && zoomXBMenuItem.checked : xOk;
                xOk = zoomXTMenuItem.enabled ? xOk && zoomXTMenuItem.checked : xOk;
                xOk = zoomLogXBMenuItem.enabled ? xOk && zoomLogXBMenuItem.checked : xOk;
                xOk = zoomLogXTMenuItem.enabled ? xOk && zoomLogXTMenuItem.checked : xOk;
                yOk = zoomYLMenuItem.enabled ? yOk && zoomYLMenuItem.checked : yOk;
                yOk = zoomYRMenuItem.enabled ? yOk && zoomYRMenuItem.checked : yOk;
                yOk = zoomLogYLMenuItem.enabled ? yOk && zoomLogYLMenuItem.checked : yOk;
                yOk = zoomLogYRMenuItem.enabled ? yOk && zoomLogYRMenuItem.checked : yOk;

                return [xOk,yOk];
            }
            /// <summary>
            /// Sends the values of the zoom menu items to the manager and, if needed,
            /// modify the autoscale menu items
            /// </summary>
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

                var checks = checkZoomEnabled();

                zoomMenuItem.text = checks[0]&&checks[1] ? "Disable zoom" : "Enable zoom";
                zoomXMenuItem.text = checks[0] ? "Disable all X" : "Enable all X";
                zoomYMenuItem.text = checks[1] ? "Disable all Y" : "Enable all Y";

                manager.setZoomAllowed(toSend);
                if (!autoDerived) zoomToAuto();
            }
            /// <summary>
            /// Modify autoscale menu items accordingly to the zoom menu items state
            /// </summary>
            function zoomToAuto(){
                zoomDerived = true;
                singleAutoTrigger = false;
                if(zoomXBMenuItem.checked){
                    autoXBMenuItem.checked = false;
                }
                if(zoomXTMenuItem.checked){
                    autoXTMenuItem.checked = false;
                }
                if(zoomLogXBMenuItem.checked){
                    autoLogXBMenuItem.checked = false;
                }
                if(zoomLogXTMenuItem.checked){
                    autoLogXTMenuItem.checked = false;
                }
                if(zoomYLMenuItem.checked){
                    autoYLMenuItem.checked = false;
                }
                if(zoomYRMenuItem.checked){
                    autoYRMenuItem.checked = false;
                }
                if(zoomLogYLMenuItem.checked){
                    autoLogYLMenuItem.checked = false;
                }
                if(zoomLogYRMenuItem.checked){
                    autoLogYRMenuItem.checked = false;
                }
                singleAutoTrigger = false;
                sendAutoTriggers();
                zoomDerived = false;
            }
            /// <summary>
            /// It sets all the pan menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the pan</param>
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
                autoMenuItem.text = !value ? "Disable autoscale" : "Enable autoscale";
                autoXMenuItem.text = !value ? "Disable all X" : "Enable all X";
                autoYMenuItem.text = !value ? "Disable all Y" : "Enable all Y";
                singlePanTrigger = true;
            }
            /// <summary>
            /// It sets the X axes pan menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the pan</param>
            function allXPanTriggers(value){
                singlePanTrigger = false;
                panXMenuItem.text = value ? "Disable all X" : "Enable all X";
                panLogXBMenuItem.checked = value;
                panLogXTMenuItem.checked = value;
                panXBMenuItem.checked = value;
                panXTMenuItem.checked = value;

                sendPanTriggers();
                autoXMenuItem.text = !value ? "Disable all X" : "Enable all X";
                singlePanTrigger = true;
            }
            /// <summary>
            /// It sets the Y axes pan menu items to the input value
            /// </summary>
            /// <param name="value">Boolean: Tells wether enable or disable the pan</param>
            function allYPanTriggers(value){
                singlePanTrigger = false;
                panYMenuItem.text = value ? "Disable all Y" : "Enable all Y";
                panLogYLMenuItem.checked = value;
                panLogYRMenuItem.checked = value;
                panYLMenuItem.checked = value;
                panYRMenuItem.checked = value;

                sendPanTriggers();
                autoYMenuItem.text = !value ? "Disable all Y" : "Enable all Y";
                singlePanTrigger = true;
            }
            /// <summary>
            /// It checks whether or not all the X and Y enabled pan menu items
            /// are checked
            /// </summary>
            /// <results>
            /// List: It contains two boolean values, one for X and one for Y, that are true
            /// only if all the enabled menu items for that axis are checked
            /// </results>
            function checkPanEnabled(){
                var xOk = true;
                var yOk = true;

                xOk = panXBMenuItem.enabled ? xOk && panXBMenuItem.checked : xOk;
                xOk = panXTMenuItem.enabled ? xOk && panXTMenuItem.checked : xOk;
                xOk = panLogXBMenuItem.enabled ? xOk && panLogXBMenuItem.checked : xOk;
                xOk = panLogXTMenuItem.enabled ? xOk && panLogXTMenuItem.checked : xOk;
                yOk = panYLMenuItem.enabled ? yOk && panYLMenuItem.checked : yOk;
                yOk = panYRMenuItem.enabled ? yOk && panYRMenuItem.checked : yOk;
                yOk = panLogYLMenuItem.enabled ? yOk && panLogYLMenuItem.checked : yOk;
                yOk = panLogYRMenuItem.enabled ? yOk && panLogYRMenuItem.checked : yOk;

                return [xOk,yOk];
            }
            /// <summary>
            /// Sends the values of the pan menu items to the manager and, if needed,
            /// modify the autoscale menu items
            /// </summary>
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

                var checks = checkPanEnabled();

                panMenuItem.text = checks[0]&&checks[1] ? "Disable pan" : "Enable pan";
                panXMenuItem.text = checks[0] ? "Disable all X" : "Enable all X";
                panYMenuItem.text = checks[1] ? "Disable all Y" : "Enable all Y";

                manager.setPanAllowed(toSend);
                if (!autoDerived) panToAuto();
            }
            /// <summary>
            /// Modify autoscale menu items accordingly to the pan menu items state
            /// </summary>
            function panToAuto(){
                panDerived = true;
                singleAutoTrigger = false;
                if(panXBMenuItem.checked){
                    autoXBMenuItem.checked = false;
                }
                if(panXTMenuItem.checked){
                    autoXTMenuItem.checked = false;
                }
                if(panLogXBMenuItem.checked){
                    autoLogXBMenuItem.checked = false;
                }
                if(panLogXTMenuItem.checked){
                    autoLogXTMenuItem.checked = false;
                }
                if(panYLMenuItem.checked){
                    autoYLMenuItem.checked = false;
                }
                if(panYRMenuItem.checked){
                    autoYRMenuItem.checked = false;
                }
                if(panLogYLMenuItem.checked){
                    autoLogYLMenuItem.checked = false;
                }
                if(panLogYRMenuItem.checked){
                    autoLogYRMenuItem.checked = false;
                }
                singleAutoTrigger = false;
                sendAutoTriggers();
                panDerived = false;
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
                        enabled: xAxisB.visible
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
                        enabled: xAxisT.visible
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
                        enabled: xLogAxisB.visible
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
                        enabled: xLogAxisT.visible
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
                        enabled: yAxisL.visible
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
                        enabled: yAxisR.visible
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
                        enabled: yLogAxisL.visible
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
                        enabled: yLogAxisR.visible
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
                        enabled: xAxisB.visible
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
                        enabled: xAxisT.visible
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
                        enabled: xLogAxisB.visible
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
                        enabled: xLogAxisT.visible
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
                        enabled: yAxisL.visible
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
                        enabled: yAxisR.visible
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
                        enabled: yLogAxisL.visible
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
                        enabled: yLogAxisR.visible
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
                        enabled: xAxisB.visible
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
                        enabled: xAxisT.visible
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
                        enabled: xLogAxisB.visible
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
                        enabled: xLogAxisT.visible
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
                        enabled: yAxisL.visible
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
                        enabled: yAxisR.visible
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
                        enabled: yLogAxisL.visible
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
                        enabled: yLogAxisR.visible
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
                    manager.fixAllAxes();  // Sets the current axes ranges as default
                }
            }
        }
    }
}
