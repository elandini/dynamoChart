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

    def __init__(self,parent=None):

        QObject.__init__(self,parent)


    @Slot(int)
    def sendIt(self,code):

        '''
        {"type":ChartView.SeriesTypeLine,"name":"Primo",
                                        "color":"#FF0000","plotType":"linlin","bottom":true,
                                        "left":true,"points":false}
        '''
        toSend = {"type":"line","name":"Primo","color":"#FF0000","plotType":"linlin","bottom":True,
                  "left":True,"points":False}
        self.sendingIt.emit(toSend)
