from PySide2.QtCore import QObject, Signal, Slot, Property, QThread, QPointF
from PySide2.QtCharts import QtCharts
import numpy as np
from random import random, randrange
from time import sleep
from datetime import datetime

from dynamoAxisManager import DynamoAxisManager

STRIP = True
#STRIP = False

## Class DynamoChartManager
class DynamoChartManager(QObject):

    # Signals ----------------------------------------------------------------------- #

    axisDone = Signal()
    axisChanged = Signal()
    interactionEnableChanged = Signal()

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
        self._allXs = [self._xB,self._xT,self._xLogB,self._xLogT]
        self._allYs = [self._yL,self._yR,self._yLogL,self._yLogR]
        self._autoX = False
        self._autoY = False
        self._axisAssigned = False
        self._stripChart = False
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

    ## Returns the y axis limits for a specific series
    # @param seriesName String: The series to inspect
    def getYLimits(self,seriesName):

        seriesPoints = self._seriesDict[seriesName].points()
        seriesY = np.array([p.y() for p in seriesPoints])

        return np.min(seriesY),np.max(seriesY)


    ## Searches for the lowest x value among the available series
    def getLowerXForStrip(self):

        minX = None
        for k in self._seriesDict.keys():
            tempLim = self.getXLimits(k)
            if minX is None or tempLim[0]<minX:
                minX = tempLim[0]
        return minX


    ## Manages the autoscaling of a single axis
    # @param manager DynamoAxisManager: The axis to manage
    # @param seriesName String: The series to set scale on
    def checkManagerScale(self, manager, seriesName):

        if self._execLog:
            print('{1}.checkManagerScale called at\t{0}'.format(datetime.now(), type(self).__name__))

        if manager.getFirstRound():
            manager.adaptToSeries(seriesName)
        else:
            manager.autoScaleLemma(seriesName)


    ## Performs an autoscaling around a specific series
    # @param seriesName String: The series to set scale on
    def checkSeriesScale(self,seriesName):

        if self._execLog:
            print('{1}.checkSeriesScale called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._autoX:
            for m in self._allXs:
                if m.registered(seriesName):
                    self.checkManagerScale(m,seriesName)
        if self._autoY:
            for m in self._allYs:
                if m.registered(seriesName):
                    self.checkManagerScale(m,seriesName)

        if self._autoY or self._autoX:
            self.fixAxis()


    ## Performs an autoscale operation on a particular axis when a new point is added or removed
    # @param manager DynamoAxisManager: The axis to manage
    def checkManagerPointScale(self,manager):

        if self._execLog:
            print('{1}.checkManagerPointScale called at\t{0}'.format(datetime.now(), type(self).__name__))

        manager.autoScalePoint()


    ## Checks whether or not a point added changes the x and y axis scale when on autoscale
    # @param seriesName String: The series the point has been added to
    # @param x Float: Point x value
    # @param y Float: Point y value
    def checkPointScale(self,seriesName,x,y):

        if self._autoX:
            for m in self._allXs:
                if m.registered(seriesName):
                    self.checkManagerPointScale(m)
        if self._autoY:
            for m in self._allYs:
                if m.registered(seriesName):
                    self.checkManagerPointScale(m)

    # ------------------------------------------------------------------------------- #

    # Slot--------------------------------------------------------------------------- #

    ## Clears all the axis and the series dictionary
    @Slot()
    def clear(self):

        if self._execLog:
            print('{1}.clear called at\t{0}'.format(datetime.now(), type(self).__name__))

        for a in self._allXs:
            a.clearAxis()
        for a in self._allYs:
            a.clearAxis()
        self._seriesDict = {}


    ## Uses current axes limits as default zoom level
    @Slot()
    def fixAxis(self):

        self._xB.fixAxis()
        self._yL.fixAxis()
        self._xT.fixAxis()
        self._yR.fixAxis()
        self._xLogB.fixAxis()
        self._yLogL.fixAxis()
        self._xLogT.fixAxis()
        self._yLogR.fixAxis()


    ## Sets all the axes to their default values
    @Slot()
    def resetAxis(self):

        self._xB.resetAxis()
        self._yL.resetAxis()
        self._xT.resetAxis()
        self._yR.resetAxis()
        self._xLogB.resetAxis()
        self._yLogL.resetAxis()
        self._xLogT.resetAxis()
        self._yLogR.resetAxis()


    ## Adds a series to the chart
    # @param seriesFeatures Dictionary: A dictionary containing all the features of the series to add
    @Slot(dict)
    def addSeries(self,test):

        testDict = test.toVariant()

        self._seriesDict[testDict["series"].name()] = testDict["series"]
        if testDict["bottom"]:
            if testDict["plotType"] == "loglog" or testDict["plotType"] == "loglin":
                self._xLogB.addSeries(testDict["series"],True)
            else:
                self._xB.addSeries(testDict["series"],True)
        else:
            if testDict["plotType"] == "loglog" or testDict["plotType"] == "loglin":
                self._xLogT.addSeries(testDict["series"],True)
            else:
                self._xT.addSeries(testDict["series"],True)
        if testDict["left"]:
            if testDict["plotType"] == "loglog" or testDict["plotType"] == "linlog":
                self._yLogL.addSeries(testDict["series"],False)
            else:
                self._yL.addSeries(testDict["series"],False)
        else:
            if testDict["plotType"] == "loglog" or testDict["plotType"] == "linlog":
                self._yLogR.addSeries(testDict["series"],False)
            else:
                self._yR.addSeries(testDict["series"],False)


    @Slot('QVariant')
    def zoom(self,qZoomDict):

        zoomDict = qZoomDict.toVariant()

        if zoomDict["direction"] == "both":
            self._xB.zoom(zoomDict["verse"])
            self._xLogB.zoom(zoomDict["verse"])
            self._xT.zoom(zoomDict["verse"])
            self._xLogT.zoom(zoomDict["verse"])
            self._yL.zoom(zoomDict["verse"])
            self._yLogL.zoom(zoomDict["verse"])
            self._yR.zoom(zoomDict["verse"])
            self._yLogR.zoom(zoomDict["verse"])
        elif zoomDict["direction"] == "x":
            self._xB.zoom(zoomDict["verse"])
            self._xLogB.zoom(zoomDict["verse"])
            self._xT.zoom(zoomDict["verse"])
            self._xLogT.zoom(zoomDict["verse"])
        elif zoomDict["direction"] == "y":
            self._yL.zoom(zoomDict["verse"])
            self._yLogL.zoom(zoomDict["verse"])
            self._yR.zoom(zoomDict["verse"])
            self._yLogR.zoom(zoomDict["verse"])


    ## Replaces all series points with new ones
    # @param inputDict Dictionary: A dictionary containing the series index, an x value list and an y values one
    @Slot('QVariant')
    def replaceSeries(self,inputDict):

        if self._stillDrawing:
            return
        self._stillDrawing = True
        points = []
        newX = inputDict["x"]
        newY = inputDict["y"]
        for i in range(len(newX)):
            point = QPointF(newX[i], newY[i])
            points.append(point)
        self._seriesDict[inputDict["index"]].replace(points)
        self.checkSeriesScale(inputDict["index"])
        self._stillDrawing = False


    ## Adds a point to one or more series
    # @param newPointsDict Dictionary: The keys are the series indexes and the values are lists with the x and y values
    @Slot(dict)
    def addPoint(self,newPointsDict):

        for k in newPointsDict.keys():
            self._seriesDict[k].append(*newPointsDict[k])
            if self._stripChart:
                if self._seriesDict[k].count() > self._stripPoints:
                    self._seriesDict[k].remove(0)
            if self._autoY or self._autoX:
                self.checkPointScale(k,*newPointsDict[k])


    ## Sets the autoscale values
    # @param qAutoscaleValDict QJSValue: Contains two booleans for x and y axis
    @Slot('QVariant')
    def setAutoScale(self,qAutoscaleValDict):

        autoScaleValDict = qAutoscaleValDict.toVariant()
        self._autoX = autoScaleValDict["x"]
        self._autoY = autoScaleValDict["y"]
        if self._autoX:
            for m in self._allXs:
                m.prepareForAutoscale()
        if self._autoY:
            for m in self._allYs:
                m.prepareForAutoscale()


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


    def xBottom(self):

        return self._xB.getInnerAxis()


    def yLeft(self):

        return self._yL.getInnerAxis()


    def xTop(self):

        return self._xT.getInnerAxis()


    def yRight(self):

        return self._yR.getInnerAxis()


    ## Sets self._axisAssigned value
    def setAxisAssigned(self,value):

        if self._execLog:
            print('{1}.setAxisAssigned called at\t{0}'.format(datetime.now(), type(self).__name__))
        if value == self._axisAssigned:
            return
        self._axisAssigned = value


    ## Sets self._interactionEnabled value
    def setInteractionEnabled(self, value):

        if self._execLog:
            print('{1}.setInteractionEnabled called at\t{0}'.format(datetime.now(), type(self).__name__))
        if value == self._interactionEnabled:
            return
        self._interactionEnabled = value


    def setXBottom(self,x):

        if x == self._xB.getInnerAxis():
            return

        self._xB.setInnerAxis(x)


    def setYLeft(self, y):

        if y == self._yL.getInnerAxis():
            return

        self._yL.setInnerAxis(y)


    def setXTop(self,x):

        if x == self._xT.getInnerAxis():
            return

        self._xT.setInnerAxis(x)


    def setYRight(self, y):

        if y == self._yR.getInnerAxis():
            return

        self._yR.setInnerAxis(y)


    def xLogBottom(self):

        return self._xLogB.getInnerAxis()


    def yLogLeft(self):

        return self._yLogL.getInnerAxis()


    def xLogTop(self):

        return self._xLogT.getInnerAxis()


    def yLogRight(self):

        return self._yLogR.getInnerAxis()


    def setXLogBottom(self,x):

        if x == self._xLogB.getInnerAxis():
            return

        self._xLogB.setInnerAxis(x)


    def setYLogLeft(self, y):

        if y == self._yLogL.getInnerAxis():
            return

        self._yLogL.setInnerAxis(y)


    def setXLogTop(self,x):

        if x == self._xLogT.getInnerAxis():
            return

        self._xLogT.setInnerAxis(x)


    def setYLogRight(self, y):

        if y == self._yLogR.getInnerAxis():
            return

        self._yLogR.setInnerAxis(y)

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
    axisAssigned = Property(bool,fget=axisAssigned, fset=setAxisAssigned, notify=axisDone)
    interactionEnabled = Property(bool,fget=interactionEnabled, fset=setInteractionEnabled, notify=interactionEnableChanged)
    # ------------------------------------------------------------------------------- #