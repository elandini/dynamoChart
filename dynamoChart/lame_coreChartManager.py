## This module contains a class derived from the DynamoChartManager for LaMe_Core library core objects

from PySide2.QtCore import QObject, Signal, Slot, Property, QPointF
import numpy as np
from datetime import datetime

from dynamoChart.dynamoChartManager import DynamoChartManager
from .definitions import *



## @class LaMe_CoreChartManager
class LaMe_CoreChartManager(DynamoChartManager):

    # Generic elements -------------------------------------------------------------- #
    colors = ["#ff3300","#0066cc","#006600","#cc66ff",
              "#800000","#0000ff","#00cc66","#ff6699",
              "#993300","#33ccff","#669900","#6600ff",
              "#ff9900","#000066","#006666","#660066"]
    # ------------------------------------------------------------------------------- #

    ## Class constructor
    # @param secondary Boolean: If True, the manager will only consider y3 and/or y4 labelled data from the core
    # @param scatter Boolean: If True, the series plotted on the chart will be "scatter" type
    # @param parent QObject: The parent object
    # @param verbose Boolean: If True enables a series of print useful for debugging
    # @param execlog Boolean: If True all the class member functions will print their name when called
    def __init__(self, secondary, scatter, parent=None, verbose=False, execlog=False):

        DynamoChartManager.__init__(self,parent,verbose,execlog)
        self._secondary = secondary
        self._scatter = scatter
        self._currentChartDict = None  # Used to store the used portion of the plotType dict provided by the core
        #                                currently connected to the chartManager
        self._currentXIndex = None
        self._currentYIndexes = None
        self._currentAxesType = None


    ## Initializes the series for a new core
    # @param chartDict Dict: A Dictionary containing the values used to initialize the chart
    def initSeries(self,chartDict):

        if self._execLog:
            print('{1}.initSeries called at\t{0}'.format(datetime.now(), type(self).__name__))

        '''
        {"type":ChartView.SeriesTypeLine,"name":"Primo",
         "color":"#FF0000","plotType":"linlin","bottom":true,
         "left":true,"points":false}
        '''
        for s in self._currentYIndexes:
            toSet = {"type":SCATTER if self._scatter else LINE, "points": True, "bottom": True,
                     "plotType": self._currentAxesType, "markerSize": MARKERSIZE,
                     "name": chartDict[s]["name"], "color": chartDict["color"], "left": chartDict["left"]}
            self.addSeries(toSet)

    # ------------------------------------------------------------------------------- #

    # Slot--------------------------------------------------------------------------- #

    ## Obtains and sets the plottype from the core
    # @param plotType Dict: The dictionary containing the plot features
    @Slot(dict)
    def setPlotType(self,plotType):

        if self._execLog:
            print('{1}.setPlotType called at\t{0}'.format(datetime.now(), type(self).__name__))

        self.clear()
        plotTypeSample = {}
        baseLegKey = "legends_{0}"
        baseLabelKey = "label_{0}"
        xIndex = None
        yAIndexes = []
        yBIndexes = []
        yA = None
        yB = None

        xIndexes = [plotType["data_indexes"].index(i) for i in plotType["data_indexes"] if type(i)!=list]

        if self._secondary:
            yA = "y3"
            x = "x2"
            xIndex = plotType["data_indexes"][xIndexes[1]]
            yAIndexes = plotType["data_indexes"][xIndexes[1]+1]
            if baseLegKey.format("y4") in plotType.keys():
                yB = "y4"
                yBIndexes = plotType["data_indexes"][xIndexes[1]+2]

        else:
            yA = "y1"
            x = "x"
            xIndex = plotType["data_indexes"][0]
            yAIndexes = plotType["data_indexes"][1]
            if baseLegKey.format("y2") in plotType.keys():
                yB = "y2"
                yBIndexes = plotType["data_indexes"][1]

        self._currentXIndex = xIndex
        self._currentYIndexes = yAIndexes+yBIndexes
        self._currentAxesType = plotType["axis_type"]
        self._currentChartDict = {}
        if plotType["axis_type"] == LIN:
            self._xB.setAxisTitle(plotType[baseLabelKey.format(x)])
            self._yL.setAxisTitle(plotType[baseLabelKey.format(yA)])
            if yB is not None:
                self._yR.setAxisTitle(plotType[baseLabelKey.format(yB)])
        elif plotType["axis_type"] == LOGX:
            self._xLogB.setAxisTitle(plotType[baseLabelKey.format(x)])
            self._yL.setAxisTitle(plotType[baseLabelKey.format(yA)])
            if yB is not None:
                self._yR.setAxisTitle(plotType[baseLabelKey.format(yB)])
        elif plotType["axis_type"] == LOGY:
            self._xB.setAxisTitle(plotType[baseLabelKey.format(x)])
            self._yLogL.setAxisTitle(plotType[baseLabelKey.format(yA)])
            if yB is not None:
                self._yLogR.setAxisTitle(plotType[baseLabelKey.format(yB)])
        elif plotType["axis_type"] == LOGLOG:
            self._xLogB.setAxisTitle(plotType[baseLabelKey.format(x)])
            self._yLogL.setAxisTitle(plotType[baseLabelKey.format(yA)])
            if yB is not None:
                self._yLogR.setAxisTitle(plotType[baseLabelKey.format(yB)])
        colorIndex = 0
        for i in range(len(yAIndexes)):
            tempSeries = {"name":plotType[baseLegKey.format(yA)][i],
                          "left":True,"color":self.colors[colorIndex%len(self.colors)]}
            colorIndex += 1
            self._currentChartDict[yAIndexes[i]] = tempSeries
        for i in range(len(yBIndexes)):
            tempSeries = {"name":plotType[baseLegKey.format(yB)][i],
                          "left":False,"color":self.colors[colorIndex%len(self.colors)]}
            colorIndex += 1
            self._currentChartDict[yBIndexes[i]] = tempSeries
        self.initSeries(self._currentChartDict)


    ## Receives data from the core and translates them for the father class methods
    # @param dataDict Dict: The data from the LaMe_Core core
    @Slot(dict)
    def getCoreData(self,dataDict):

        if self._execLog:
            print('{1}.getCoreData called at\t{0}'.format(datetime.now(), type(self).__name__))

        dataList = dataDict["data"]
        if type(dataList[0]) == list:
            xList = dataList[self._currentXIndex]
            for y in self._currentYIndexes:
                toSend = {"name": self._currentChartDict[y]["name"],
                          "x": xList, "y": dataList[y]}
                self.replaceSeries(toSend)
        else:
            xData = dataList[self._currentXIndex]
            toSend = {}
            for y in self._currentYIndexes:
                toSend[self._currentChartDict[y]["name"]] = [xData,dataList[y]]
            self.addPoint(toSend)

