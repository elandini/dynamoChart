from PySide2.QtCore import QObject, Signal, Slot, Property, QPointF
from PySide2.QtCharts import QtCharts
import numpy as np
from datetime import datetime

from .dynamoAxisManager import DynamoAxisManager
from .definitions import *

STRIP = True
#STRIP = False

## Class DynamoChartManager
class DynamoChartManager(QObject):

    # Signals ----------------------------------------------------------------------- #

    axisAssignedChanged = Signal(bool)
    axisChanged = Signal()
    interactionEnableChanged = Signal()
    addingSeries = Signal('QVariant')
    errorSignal = Signal(str)
    cleared = Signal()

    # ------------------------------------------------------------------------------- #

    # General purpose functions ----------------------------------------------------- #

    ## Class constructor
    # @param parent QObject: The parent object
    # @param verbose Boolean: If True enables a series of print useful for debugging
    # @param execlog Boolean: If True all the class member functions will print their name when called
    def __init__(self,parent=None,verbose=False,execlog=False):

        if execlog:
            print('{1}.__init__ called at\t{0}'.format(datetime.now(), type(self).__name__))

        QObject.__init__(self,parent)
        self._seriesDict = {}
        self._xB = DynamoAxisManager(self,scalefactor=1.28)
        self._yL = DynamoAxisManager(self,scalefactor=1.28)
        self._xT = DynamoAxisManager(self,scalefactor=1.28)
        self._yR = DynamoAxisManager(self,scalefactor=1.28)
        self._xLogB = DynamoAxisManager(self)
        self._yLogL = DynamoAxisManager(self)
        self._xLogT = DynamoAxisManager(self)
        self._yLogR = DynamoAxisManager(self)
        self._xB.setObjectName("xB")
        self._xT.setObjectName("xT")
        self._xLogB.setObjectName("xLogB")
        self._xLogT.setObjectName("xLogT")
        self._yL.setObjectName("yL")
        self._yR.setObjectName("yR")
        self._yLogL.setObjectName("yLogL")
        self._yLogR.setObjectName("yLogR")
        self._assignedX = {}
        self._assignedY = {}
        self._axisAssigned = False
        self._stripChart = False
        self._stillDrawing = False
        self._interactionEnabled = True
        self._stripPoints = 0
        self._verbose = verbose
        self._execLog = execlog


    ## Returns the x axis limits for a specific series
    # @param seriesName String: The series to inspect
    def getXLimits(self,seriesName):

        seriesPoints = self._seriesDict[seriesName].points()
        seriesX = np.array([p.x() for p in seriesPoints])

        return np.min(seriesX),np.max(seriesX)


    ## Manages the autoscaling of a single axis
    # @param manager DynamoAxisManager: The axis to manage
    # @param seriesName String: The series to set scale on
    def singleAxisAutoscale(self, manager, seriesName):

        if self._execLog:
            print('{1}.singleAxisAutoscale called at\t{0}'.format(datetime.now(), type(self).__name__))

        manager.autoScaleLemma(seriesName)


    ## Performs an autoscaling around a specific series
    # @param seriesName String: The series to set scale on
    def seriesWiseAutoscale(self,seriesName):

        if self._execLog:
            print('{1}.seriesWiseAutoscale called at\t{0}'.format(datetime.now(), type(self).__name__))

        for kx in self._assignedX.keys():
            if self._assignedX[kx].autoscaling:
                self.singleAxisAutoscale(self._assignedX[kx],seriesName)
                self._assignedX[kx].fixAxis()
        for ky in self._assignedY.keys():
            if self._assignedY[ky].autoscaling:
                self.singleAxisAutoscale(self._assignedY[ky],seriesName)
                self._assignedY[ky].fixAxis()


    ## Performs an autoscale operation on a particular axis when a new point is added or removed
    # @param manager DynamoAxisManager: The axis to manage
    # @param seriesName String: The series the point has been added to
    def singleAxisPointScale(self,manager,seriesName):

        if self._execLog:
            print('{1}.singleAxisPointScale called at\t{0}'.format(datetime.now(), type(self).__name__))

        manager.autoScalePoint(seriesName)


    ## Checks whether or not a point added changes the x and y axis scale when on autoscale
    # @param seriesName String: The series the point has been added to
    def pointWiseAutoscale(self,seriesName):

        if self._execLog:
            print('{1}.pointwiseAutoscale called at\t{0}'.format(datetime.now(), type(self).__name__))

        for kx in self._assignedX.keys():
            if self._assignedX[kx].autoscaling:
                self.singleAxisPointScale(self._assignedX[kx],seriesName)
                self._assignedX[kx].fixAxis()
        for ky in self._assignedY.keys():
            if self._assignedY[ky].autoscaling:
                self.singleAxisPointScale(self._assignedY[ky],seriesName)
                self._assignedY[ky].fixAxis()


    ## Returns the axis managed by the provided manager
    # @param manager DynamoAxisManager: The wanted manager
    def _getManagedAxis(self,manager):

        if self._execLog:
            print('{1}._getManagedAxis called at\t{0}'.format(datetime.now(), type(self).__name__))

        return manager.getInnerAxis()


    ## Sets the axis managed by the provided manager
    # @param manager DynamoAxisManager: The wanted manager
    # @param managed AbstractAxis: The axis to set
    # @param isX Boolean: If True the axis is an X axis, if False is an Y one
    def _setManagedAxis(self,manager, managed, isX):

        if self._execLog:
            print('{1}._setManagedAxis called at\t{0}'.format(datetime.now(), type(self).__name__))

        if managed == manager.getInnerAxis():
            return
        if manager.getInnerAxis() is not None:
            if isX:
                self._assignedX.pop(manager.getInnerAxis().objectName())
                self._assignedX[managed.objectName()] = manager
            else:
                self._assignedY.pop(manager.getInnerAxis().objectName())
                self._assignedY[managed.objectName()] = manager
        else:
            if isX:
                self._assignedX[managed.objectName()] = manager
            else:
                self._assignedY[managed.objectName()] = manager
        manager.setInnerAxis(managed)

    # ------------------------------------------------------------------------------- #

    # Slot--------------------------------------------------------------------------- #

    ## Clears all the axis and the series dictionary
    @Slot()
    def clear(self):

        if self._execLog:
            print('{1}.clear called at\t{0}'.format(datetime.now(), type(self).__name__))

        for k in self._assignedX.keys():
            self._assignedX[k].clearAxis()
        for k in self._assignedY.keys():
            self._assignedY[k].clearAxis()
        self._seriesDict = {}
        self.cleared.emit()


    ## Removes all the points from the currently available series
    @Slot()
    def emptySeries(self):

        if self._execLog:
            print('{1}.emptySeries called at\t{0}'.format(datetime.now(), type(self).__name__))
        for k in self._seriesDict.keys():
            self._seriesDict[k].removePoints(0,self._seriesDict[k].count())


    ## It fixes a set of selected axes
    # @param qAxesSet QJSValue: The dictionary containing the axis to fix
    @Slot('QVariant')
    def fixAxes(self,qAxesSet):

        if self._execLog:
            print('{1}.fixAxes called at\t{0}'.format(datetime.now(), type(self).__name__))
        axesSet = qAxesSet.toVariant()
                                                                                                                                                                                                                                                                                                                                        
        for a in axesSet["x"]:
            self._assignedX[a].fixAxis()
        for a in axesSet["y"]:
            self._assignedY[a].fixAxis()
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

    ## Uses current axes limits as default zoom level
    @Slot()
    def fixAllAxes(self):

        if self._execLog:
            print('{1}.fixAllAxes called at\t{0}'.format(datetime.now(), type(self).__name__))

        for k in self._assignedX.keys():
            self._assignedX[k].fixAxis()
        for k in self._assignedY.keys():
            self._assignedY[k].fixAxis()


    ## Sets all the axes to their default values
    @Slot()
    def resetAllAxis(self):

        if self._execLog:
            print('{1}.resetAllAxis called at\t{0}'.format(datetime.now(), type(self).__name__))

        for k in self._assignedX.keys():
            self._assignedX[k].resetAxis()
        for k in self._assignedY.keys():
            self._assignedY[k].resetAxis()


    ## Sends the info needed to add a series to the managed QML object
    # @param seriesFeatures Dictionary: The new series features
    @Slot(dict)
    def addSeries(self,seriesFeatures):

        if self._execLog:
            print('{1}.addSeries called at\t{0}'.format(datetime.now(), type(self).__name__))

        if seriesFeatures["type"] not in ALLOWED.keys():
            self.errorSignal.emit("Wrong series type")
            return
        seriesFeatures["type"] = ALLOWED[seriesFeatures["type"]]  # The series type, in qml is a number and, since for
        #                                                           clarity sake the "type" value in the input
        #                                                           dictionary is a string that report a human readable
        #                                                           name for the type, before sending the dictionary to
        #                                                           the QML object, the "type" value has to be replaced
        #                                                           with the correspondent number
        self.addingSeries.emit(seriesFeatures)


    ## Adds a series to the chart
    # @param qSeriesFeatures QJSValue: A dictionary containing all the features of the series to add
    @Slot('QVariant')
    def registerSeries(self,qSeriesFeatures):
        
        if self._execLog:
            print('{1}.registerSeries called at\t{0}'.format(datetime.now(), type(self).__name__))

        seriesFeatures = qSeriesFeatures.toVariant()

        self._seriesDict[seriesFeatures["series"].name()] = seriesFeatures["series"]
        if seriesFeatures["bottom"]:
            if seriesFeatures["plotType"] == "loglog" or seriesFeatures["plotType"] == "loglin":
                self._xLogB.addSeries(seriesFeatures["series"],True)
            else:
                self._xB.addSeries(seriesFeatures["series"],True)
        else:
            if seriesFeatures["plotType"] == "loglog" or seriesFeatures["plotType"] == "loglin":
                self._xLogT.addSeries(seriesFeatures["series"],True)
            else:
                self._xT.addSeries(seriesFeatures["series"],True)
        if seriesFeatures["left"]:
            if seriesFeatures["plotType"] == "loglog" or seriesFeatures["plotType"] == "linlog":
                self._yLogL.addSeries(seriesFeatures["series"],False)
            else:
                self._yL.addSeries(seriesFeatures["series"],False)
        else:
            if seriesFeatures["plotType"] == "loglog" or seriesFeatures["plotType"] == "linlog":
                self._yLogR.addSeries(seriesFeatures["series"],False)
            else:
                self._yR.addSeries(seriesFeatures["series"],False)


    @Slot('QVariant')
    def zoom(self,qZoomDict):
        
        if self._execLog:
            print('{1}.zoom called at\t{0}'.format(datetime.now(), type(self).__name__))

        zoomDict = qZoomDict.toVariant()
        for k in self._assignedX.keys():
            if self._assignedX[k].zoomAllowed:
                self._assignedX[k].zoom(zoomDict["verse"])
        for k in self._assignedY.keys():
            if self._assignedY[k].zoomAllowed:
                self._assignedY[k].zoom(zoomDict["verse"])


    ## Performs a pan on the x direction
    # @param qPanXDict QJSValue: A dictionary containing the pan to perform as a normalized step and a code that represents the axes to perform the pan on
    @Slot('QVariant')
    def panX(self,qPanXDict):

        if self._execLog:
            print('{1}.panX called at\t{0}'.format(datetime.now(), type(self).__name__))
        panXDict = qPanXDict.toVariant()
        for k in self._assignedX.keys():
            if self._verbose:
                print("Is it allowed on {0}? {1}".format(k,self._assignedX[k].panAllowed))
            if self._assignedX[k].panAllowed:
                self._assignedX[k].pan(panXDict["normDelta"])


    ## Performs a pan on the y direction
    # @param qPanYDict QJSValue: A dictionary containing the pan to perform as a normalized step and a code that represents the axes to perform the pan on
    @Slot('QVariant')
    def panY(self, qPanYDict):

        if self._execLog:
            print('{1}.panY called at\t{0}'.format(datetime.now(), type(self).__name__))
        panYDict = qPanYDict.toVariant()
        for k in self._assignedY.keys():
            if self._assignedY[k].panAllowed:
                self._assignedY[k].pan(panYDict["normDelta"])


    ## Replaces all series points with new ones
    # @param inputDict Dictionary: A dictionary containing the series names as keys and a list with x values list and an y values one
    @Slot(dict)
    def replaceSeries(self,inputDict):

        if self._execLog:
            print('{1}.replaceSeries called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._verbose:
            print("To replace: {0}".format(inputDict))

        if self._stillDrawing:
            return
        self._stillDrawing = True
        for k in inputDict.keys():
            points = []
            newX = inputDict[k][0]
            newY = inputDict[k][1]
            for i in range(len(newX)):
                point = QPointF(newX[i], newY[i])
                points.append(point)
            self._seriesDict[k].replace(points)
            self.seriesWiseAutoscale(k)
        self._stillDrawing = False


    ## Adds a point to one or more series
    # @param newPointsDict Dictionary: The keys are the series indexes and the values are lists with the x and y values
    @Slot(dict)
    def addPoint(self,newPointsDict):

        if self._execLog:
            print('{1}.addPoint called at\t{0}'.format(datetime.now(), type(self).__name__))

        for k in newPointsDict.keys():
            self._seriesDict[k].append(*newPointsDict[k])
            if self._stripChart:
                if self._seriesDict[k].count() > self._stripPoints:
                    self._seriesDict[k].remove(0)
            self.pointWiseAutoscale(k)


    ## Sets the autoscale values
    # @param qAutoscaleValDict QJSValue: Contains two booleans for x and y axis
    @Slot('QVariant')
    def setAutoScale(self,qAutoscaleValDict):

        if self._execLog:
            print('{1}.setAutoScale called at\t{0}'.format(datetime.now(), type(self).__name__))

        autoScaleValDict = qAutoscaleValDict.toVariant()
        if self._verbose:
            print("Auto Got: {0}".format(autoScaleValDict))
        for k in autoScaleValDict["x"].keys():
            self._assignedX[k].autoscaling = autoScaleValDict["x"][k]
        for k in autoScaleValDict["y"].keys():
            self._assignedY[k].autoscaling = autoScaleValDict["y"][k]


    ## Sets the label for a selected set of axis
    # @param qAxesDict QJSValue: Contains the labels to change and the name of the axes whose label to set
    @Slot('QVariant')
    def setAxesLabels(self,qAxesDict):

        if self._execLog:
            print('{1}.setAxesLabels called at\t{0}'.format(datetime.now(), type(self).__name__))

        axesDict = qAxesDict.toVariant()

        for k in axesDict.keys():
            if k in self._assignedX.keys():
                self._assignedX[k].setAxisTitle(axesDict[k])
            elif k in self._assignedY.keys():
                self._assignedY[k].setAxisTitle(axesDict[k])
            else:
                continue


    ## Sets the zoom values
    # @param qZoomValDict QJSValue: Contains two booleans for x and y axis
    @Slot('QVariant')
    def setZoomAllowed(self, qZoomValDict):

        zoomValDict = qZoomValDict.toVariant()
        for k in zoomValDict["x"].keys():
            self._assignedX[k].zoomAllowed = zoomValDict["x"][k]
        for k in zoomValDict["y"].keys():
            self._assignedY[k].zoomAllowed = zoomValDict["y"][k]


    ## Sets the pan values
    # @param qPanValDict QJSValue: Contains two booleans for x and y axis
    @Slot('QVariant')
    def setPanAllowed(self, qPanValDict):

        panValDict = qPanValDict.toVariant()
        if self._verbose:
            print("Pan Got: {0}".format(panValDict))
        for k in panValDict["x"].keys():
            if self._verbose:
                print("x setting {0} on {1} axis".format(panValDict["x"][k],k))
            self._assignedX[k].panAllowed = panValDict["x"][k]
            if self._verbose:
                print("x axis {1} is {0} now".format(self._assignedX[k].panAllowed,k))
        for k in panValDict["y"].keys():
            if self._verbose:
                print("y setting {0} on {1} axis".format(panValDict["y"][k],k))
            self._assignedY[k].panAllowed = panValDict["y"][k]
            if self._verbose:
                print("y axis {1} is {0} now".format(self._assignedY[k].panAllowed,k))


    ## Sets whether or not the chart has to behave as a strip chart and the number of points for the chart
    # @param qStripSet QJSValue: The settings dictionary
    @Slot('QVariant')
    def setStripChart(self,qStripSet):

        stripSet = qStripSet.toVariant()
        self._stripChart = stripSet["doStrip"]
        self._stripPoints = stripSet["points"]

    # ------------------------------------------------------------------------------- #

    # Properties changing functions ------------------------------------------------- #

    ## Returns the self._axisAssigned value
    def axisAssigned(self):

        if self._execLog:
            print('{1}.axisAssigned called at\t{0}'.format(datetime.now(), type(self).__name__))
        return self._axisAssigned


    ## Returns the current value for self._interactionEnabled
    def interactionEnabled(self):

        if self._execLog:
            print('{1}.interactionEnabled called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._interactionEnabled


    ## Returns the axis managed by _xB
    def xBottom(self):

        if self._execLog:
            print('{1}.xBottom called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._xB.getInnerAxis()


    ## Returns the axis managed by _yL
    def yLeft(self):

        if self._execLog:
            print('{1}.yLeft called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._yL.getInnerAxis()


    ## Returns the axis managed by _xT
    def xTop(self):

        if self._execLog:
            print('{1}.xTop called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._xT.getInnerAxis()


    ## Returns the axis managed by _yR
    def yRight(self):

        if self._execLog:
            print('{1}.yRight called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._yR.getInnerAxis()


    ## Returns the axis managed by _xLogB
    def xLogBottom(self):

        if self._execLog:
            print('{1}.xLogBottom called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._xLogB.getInnerAxis()


    ## Returns the axis managed by _yLogL
    def yLogLeft(self):

        if self._execLog:
            print('{1}.yLogLeft called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._yLogL.getInnerAxis()


    ## Returns the axis managed by _xLogT
    def xLogTop(self):

        if self._execLog:
            print('{1}.xLogTop called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._xLogT.getInnerAxis()


    ## Returns the axis managed by _yLogR
    def yLogRight(self):

        if self._execLog:
            print('{1}.yLogRight called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._yLogR.getInnerAxis()


    ## Sets self._axisAssigned value
    # @param value Boolean: The value to assign
    def setAxisAssigned(self,value):

        if self._execLog:
            print('{1}.setAxisAssigned called at\t{0}'.format(datetime.now(), type(self).__name__))
        if self._verbose:
            print("axisAssigned: {0}; value: {1}".format(self._axisAssigned,value))
        if value == self._axisAssigned:
            return
        self._axisAssigned = value
        self.axisAssignedChanged.emit(value)


    ## Sets self._interactionEnabled value
    # @param value Boolean: The value to assign
    def setInteractionEnabled(self, value):

        if self._execLog:
            print('{1}.setInteractionEnabled called at\t{0}'.format(datetime.now(), type(self).__name__))
        if value == self._interactionEnabled:
            return
        self._interactionEnabled = value


    ## Sets the axis managed by _xB
    # @param x ValueAxis: The axis to manage
    def setXBottom(self,x):

        if self._execLog:
            print('{1}.setXBottom called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._setManagedAxis(self._xB,x,True)


    ## Sets the axis managed by _yL
    # @param y ValueAxis: The axis to manage
    def setYLeft(self, y):

        if self._execLog:
            print('{1}.setYLeft called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._setManagedAxis(self._yL,y,False)


    ## Sets the axis managed by _xT
    # @param x ValueAxis: The axis to manage
    def setXTop(self,x):

        if self._execLog:
            print('{1}.setXTop called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._setManagedAxis(self._xT,x,True)


    ## Sets the axis managed by _yR
    # @param y ValueAxis: The axis to manage
    def setYRight(self, y):

        if self._execLog:
            print('{1}.setYRight called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._setManagedAxis(self._yR,y,False)


    ## Sets the axis managed by _xLogB
    # @param x LogValueAxis: The axis to manage
    def setXLogBottom(self,x):

        if self._execLog:
            print('{1}.setXLogBottom called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._setManagedAxis(self._xLogB,x,True)


    ## Sets the axis managed by _yLogL
    # @param y LogValueAxis: The axis to manage
    def setYLogLeft(self, y):

        if self._execLog:
            print('{1}.setYLogLeft called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._setManagedAxis(self._yLogL,y,False)


    ## Sets the axis managed by _xLogT
    # @param x LogValueAxis: The axis to manage
    def setXLogTop(self,x):

        if self._execLog:
            print('{1}.setXLogTop called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._setManagedAxis(self._xLogT,x,True)


    ## Sets the axis managed by _yLogR
    # @param y LogValueAxis: The axis to manage
    def setYLogRight(self, y):

        if self._execLog:
            print('{1}.setYLogRight called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._setManagedAxis(self._yLogR,y,False)

    # ------------------------------------------------------------------------------- #

    # Properties -------------------------------------------------------------------- #
    xBottom = Property(QtCharts.QValueAxis, fget=xBottom, fset=setXBottom, notify=axisChanged)
    yLeft = Property(QtCharts.QValueAxis, fget=yLeft, fset=setYLeft, notify=axisChanged)
    xTop = Property(QtCharts.QValueAxis, fget=xTop, fset=setXTop, notify=axisChanged)
    yRight = Property(QtCharts.QValueAxis, fget=yRight, fset=setYRight, notify=axisChanged)
    xLogBottom = Property(QtCharts.QLogValueAxis, fget=xLogBottom, fset=setXLogBottom, notify=axisChanged)
    yLogLeft = Property(QtCharts.QLogValueAxis, fget=yLogLeft, fset=setYLogLeft, notify=axisChanged)
    xLogTop = Property(QtCharts.QLogValueAxis, fget=xLogTop, fset=setXLogTop, notify=axisChanged)
    yLogRight = Property(QtCharts.QLogValueAxis, fget=yLogRight, fset=setYLogRight, notify=axisChanged)
    axisAssigned = Property(bool,fget=axisAssigned, fset=setAxisAssigned, notify=axisAssignedChanged)
    interactionEnabled = Property(bool,fget=interactionEnabled, fset=setInteractionEnabled, notify=interactionEnableChanged)
    # ------------------------------------------------------------------------------- #