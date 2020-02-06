from PySide2.QtCore import QObject, Signal, Slot, Property, QPointF, QTimer
from PySide2.QtCharts import QtCharts
import numpy as np
from datetime import datetime
from time import sleep


## Class DynamoChartManager
class TestThread(QObject):

    data = Signal(dict)

    def __init__(self,timer,name,ptnum,amplIncr,rampPts,parent=None):

        QObject.__init__(self,parent)

        self.pointNum = ptnum
        self.rampPoints = rampPts
        self.counterIncr = 1
        self.amplIncr = amplIncr
        self.name = name
        self.amplCounter = 1
        self.timer = timer
        self.internalTimer = None


    @Slot()
    def startTimer(self):

        self.internalTimer = QTimer(self)
        self.internalTimer.timeout.connect(self.calcData)
        self.internalTimer.setSingleShot(False)
        self.internalTimer.start(self.timer)


    def calcData(self):

        dataX = np.arange(0,self.pointNum)*2*np.pi/self.pointNum
        dataY = np.sin(dataX)*(self.amplIncr*self.amplCounter)
        toSend = {"name":self.name,"x":dataX,"y":dataY}

        self.amplCounter += self.counterIncr
        if self.amplCounter == self.rampPoints or self.amplCounter == -1*self.rampPoints:
            self.counterIncr *= -1
            self.amplCounter += self.counterIncr

        self.data.emit(toSend)


    @Slot()
    def stopTimer(self):

        if self.internalTimer is not None:
            self.internalTimer.stop()
            while self.internalTimer.isActive():
                sleep(0.05)
            self.internalTimer = None
