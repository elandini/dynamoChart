from PySide2.QtCore import QObject, Signal, Slot, Property, QPointF
from PySide2.QtCharts import QtCharts
import numpy as np
from datetime import datetime

from dynamoChart.dynamoAxisManager import DynamoAxisManager

STRIP = True
#STRIP = False

## Class DynamoChartManager
class TestObject(QObject):

    sendingIt = Signal(dict)

    def __init__(self,name,type="line",markerSize=0,bottom=True,left=True,parent=None):

        QObject.__init__(self,parent)
        self.name = name
        self.type = type
        self.bottom = bottom
        self.left = left
        self.marker = markerSize


    @Slot(int)
    def sendIt(self,code):

        '''
        {"type":ChartView.SeriesTypeLine,"name":"Primo",
                                        "color":"#FF0000","plotType":"linlin","bottom":true,
                                        "left":true,"points":false}
        '''
        toSend = {"type":self.type,"name":self.name,"color":"#FF0000","plotType":"linlin","bottom":self.bottom,
                  "left":self.left,"points":False,"markerSize":self.marker}
        print(toSend)
        self.sendingIt.emit(toSend)
