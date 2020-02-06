from PySide2.QtCore import QObject, Signal, Slot, Property, QThread, QPointF, QMutex
from PySide2.QtCharts import QtCharts
import numpy as np

from datetime import datetime

## Class DynamoAxisManager
class DynamoAxisManager(QObject):

    ## Class constructor
    # @param parent QObject: The parent object
    # @param inneraxis QAbstractAxis: The axis to manage
    # @param inputmin Double: The initial minimum value for the axis
    # @param inputmax Double: The initial maximum value for the axis
    # @param scalefactor Double: The scale value used to change the axis range when zooming
    # @param verbose Boolean: If True enables a series of print useful for debugging
    # @param execlog Boolean: If True all the class member functions will print their name when called
    def __init__(self,parent=None,inneraxis=None,inputmin=0,inputmax=100,scalefactor=2.0,verbose=False,execlog=False):

        if execlog:
            print('{1}.__init__ called at\t{0}'.format(datetime.now(), type(self).__name__))

        QObject.__init__(self,parent)

        self._defMax = inputmax
        self._defMin = inputmin
        self._scaleFactor = scalefactor
        self._innerAxis = inneraxis
        self._firstRound = True
        self._autoScaling = False
        self._zoomable = True
        self._pannable = True
        self._registeredSeries = {}  # A dictionary with the following structure:
        #                               - key = registered series name (string)
        #                               - value = series object (QAbstractSeries) + does the series use the axis as an X axis (boolean)? It's a list
        self._verbose = verbose
        self._execLog = execlog


    ## Returns the value of firstRound
    def getFirstRound(self):

        if self._execLog:
            print('{1}.getFirstRound called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._firstRound


    ## Returns the inner axis
    def getInnerAxis(self):

        if self._execLog:
            print('{1}.getInnerAxis called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return

        return self._innerAxis


    ## Returns the axis range in the form of a list [min,max]
    def getRange(self):

        if self._execLog:
            print('{1}.getRange called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return

        return [self._innerAxis.min(), self._innerAxis.max()]


    ## Returns the current axis scale factor
    def getScaleFactor(self):

        if self._execLog:
            print('{1}.getScaleFactor called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return

        return self._scaleFactor


    ## Sets inner axis
    # @param newAxis QAbstractAxis: The new inner axis
    def setInnerAxis(self, newAxis):

        if self._execLog:
            print('{1}.setInnerAxis called at\t{0}'.format(datetime.now(), type(self).__name__))

        if not isinstance(newAxis,QtCharts.QAbstractAxis):
            raise TypeError("newAxis parameter has to be a QAbstractAxis")

        self._innerAxis = newAxis
        self.clearAxis()
        self._innerAxis.setVisible(False)


    ## Sets the axis range
    # @param newRange List: A new set of minimum and maximum for the axis in a list ([min,max])
    def setRange(self, newRange):

        if self._execLog:
            print('{1}.setRange called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return

        self._innerAxis.setMin(newRange[0])
        self._innerAxis.setMax(newRange[1])


    ## Sets the scale factor for the axis
    # @param newFactor: The new scale factor to set
    def setScaleFactor(self,newFactor):

        if self._execLog:
            print('{1}.setScaleFactor called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return

        self._scaleFactor = newFactor


    ## Performs a zoom on the innerAxis
    # @param verse Integer: 1 for zoom in and -1 for zoom out
    def zoom(self,verse):

        if self._execLog:
            print('{1}.zoom called at\t{0}'.format(datetime.now(), type(self).__name__))

        if verse not in [-1,1]:
            raise ValueError("verse parameter must be either 1 or -1")
        if self._innerAxis is None or not self.used():
            return
        if self.autoscaling:
            return

        theFactor = self._scaleFactor**verse

        rangeA = np.abs(self._innerAxis.max() - self._innerAxis.min()) / theFactor
        center = (self._innerAxis.max() + self._innerAxis.min()) / 2
        newRange = [center - rangeA / 2, center + rangeA / 2]
        self.setRange(newRange)


    ## Shifts the axis range
    # @param nDelta Double: The normalized shift amplitude
    def pan(self,nDelta):

        if self._execLog:
            print('{1}.pan called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return
        if self.autoscaling:
            return

        limits = self.getRange()
        delta = nDelta*(limits[1]-limits[0])
        self.setRange([limits[0]+delta,limits[1]+delta])


    ## Uses current minimum and maximum of the inner axis as default minimum and maximum
    def fixAxis(self):

        if self._execLog:
            print('{1}.fixAxis called at\t{0}'.format(datetime.now(), type(self).__name__))
        if self._innerAxis is None:
            return

        self._defMax = self._innerAxis.max()
        self._defMin = self._innerAxis.min()


    ## Sets inner axis maximum and minimum to default values
    def resetAxis(self):

        if self._execLog:
            print('{1}.resetAxis called at\t{0}'.format(datetime.now(), type(self).__name__))
        if self._innerAxis is None:
            return

        self._innerAxis.setMax(self._defMax)
        self._innerAxis.setMin(self._defMin)
        self._zoomable = True
        self._pannable = True
        self._autoScaling = False


    ## Tells whether or not the series list is empty
    def used(self):

        if self._execLog:
            print('{1}.used called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None:
            return False

        return len(self._registeredSeries) >= 1


    ## Tells whether a series has been registered for this axis
    # @param toCheck String: The name of the series to check
    def registered(self, toCheck):

        if self._execLog:
            print('{1}.registered called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return False

        return toCheck in self._registeredSeries.keys()


    ## Adds a series name to the registered dictionary
    # @param toAdd QAbstractSeries: The series to add
    # @param asX Boolean: Tru if the series is using the inner axis as a X axis
    def addSeries(self,toAdd,asX):

        if self._execLog:
            print('{1}.addSeries called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or toAdd.name() in self._registeredSeries.keys():
            return
        enteredEmpty = not self.used()
        self._registeredSeries[toAdd.name()] = [toAdd,asX]

        if enteredEmpty:
            self._innerAxis.setVisible(True)


    ## Adds a series if the axis name specified coincides with the inner axis one
    # @param toAdd QAbstractSeries: The series to add
    # @param asX Boolean: Tru if the series is using the inner axis as a X axis
    # @param axisName String: The name of the axis the series uses
    def addIfProper(self,toAdd,asX,axisName):

        if self._execLog:
            print('{1}.addIfProper called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None:
            return
        elif axisName != self._innerAxis.objectName():
            return
        self.addSeries(toAdd,asX)


    ## Removes a series
    # @param toRemove String: The name of the series to remove
    def removeSeries(self,toRemove):

        if self._execLog:
            print('{1}.removeSeries called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used() or not self.registered(toRemove):
            return

        self._registeredSeries.pop(toRemove,None)
        self._innerAxis.setVisible(self.used())


    ## Removes all registered series
    def clearAxis(self):

        if self._execLog:
            print('{1}.clearAxis called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return

        self.resetAxis()
        self._registeredSeries = {}


    ## Returns the maximum and minimum of a registered series along the proper axis
    # @param seriesName String: The name of the series to query
    def getSeriesLimits(self,seriesName):

        if self._execLog:
            print('{1}.getSeriesLimits called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used() or not self.registered(seriesName):
            return None

        seriesPoints = self._registeredSeries[seriesName][0].points()
        if self._registeredSeries[seriesName][1]:
            toSearch = np.array([p.x() for p in seriesPoints])
        else:
            toSearch = np.array([p.y() for p in seriesPoints])


        return np.min(toSearch),np.max(toSearch)


    ## Change axis range using a certain series limits
    # @param seriesName String: The name of the series to adapt to
    def adaptToSeries(self,seriesName):

        if self._execLog:
            print('{1}.adaptToSeries called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used() or not self.registered(seriesName):
            return

        limits = self.getSeriesLimits(seriesName)
        self.setRange(limits)
        self._firstRound = False


    ## Performs an autoscaling with respect to a series
    # @param seriesName String: The name of the series to compare
    def autoScaleLemma(self,seriesName):

        if self._execLog:
            print('{1}.autoScaleLemma called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used() or not self.registered(seriesName):
            return
        limits = self.getSeriesLimits(seriesName)
        actualRange = self.getRange()
        newRange = [min(actualRange[0],limits[0]),max(actualRange[1],limits[1])]
        self.setRange(newRange)


    ## Adapt the axis range to the registered series
    def fitSeries(self):

        if self._execLog:
            print('{1}.fitSeries called at\t{0}'.format(datetime.now(), type(self).__name__))

        newRange = [self.getLowestValue(),self.getHighestValue()]
        self.setRange(newRange)


    ## Performs an autoscale with respect to a point
    def autoScalePoint(self):

        if self._execLog:
            print('{1}.autoScalePoint called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return None

        self.setRange([self.getLowestValue(),self.getHighestValue()])


    ## Gets the lowest value among all the registered series
    def getLowestValue(self):

        if self._execLog:
            print('{1}.getLowestValue called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return None

        toReturn = None
        for k in self._registeredSeries.keys():
            tempMin = self.getSeriesLimits(k)[0]
            if toReturn is None:
                toReturn = tempMin
            else:
                toReturn = min(toReturn,tempMin)

        return toReturn


    ## Returns the highest value among all the registered series
    def getHighestValue(self):

        if self._execLog:
            print('{1}.getHighestValue called at\t{0}'.format(datetime.now(), type(self).__name__))

        if self._innerAxis is None or not self.used():
            return None

        toReturn = None
        for k in self._registeredSeries.keys():
            tempMax = self.getSeriesLimits(k)[1]
            if toReturn is None:
                toReturn = tempMax
            else:
                toReturn = max(toReturn, tempMax)

        return toReturn


    ## Resets the firstRound value to True
    def prepareForAutoscale(self):

        if self._execLog:
            print('{1}.prepareForAutoscale called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._firstRound = True


    ## Returns whether or not the manager is autoScaling the axis
    @property
    def autoscaling(self):

        if self._execLog:
            print('{1}.autoscaling called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._autoScaling


    ## Sets the autoscaling property
    # @param value Boolen: The value to set
    @autoscaling.setter
    def autoscaling(self,value):

        if self._execLog:
            print('{1}.autoscaling called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._pannable = not value
        self._zoomable = not value

        if value and not self._autoScaling:
            self._firstRound = True

        self._autoScaling = value


    ## Returns whether or not the manager allows zooming
    @property
    def zoomAllowed(self):

        if self._execLog:
            print('{1}.zoomAllowed called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._zoomable


    ## Sets the zoom allowed property
    # @param value Boolen: The value to set
    @zoomAllowed.setter
    def zoomAllowed(self, value):

        if self._execLog:
            print('{1}.zoomAllowed called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._zoomable = value
        if self._autoScaling and value:
            self._autoScaling = False


    ## Returns whether or not the manager allows pan
    @property
    def panAllowed(self):

        if self._execLog:
            print('{1}.panAllowed called at\t{0}'.format(datetime.now(), type(self).__name__))

        return self._pannable


    ## Sets the pan allowed property
    # @param value Boolen: The value to set
    @panAllowed.setter
    def panAllowed(self, value):

        if self._execLog:
            print('{1}.zoomAllowed called at\t{0}'.format(datetime.now(), type(self).__name__))

        self._pannable = value
        if self._autoScaling and value:
            self._autoScaling = False

    # ------------------------------------------------------------------------------- #

    # Slots ------------------------------------------------------------------------- #

    # ------------------------------------------------------------------------------- #