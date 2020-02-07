## This module contains a class derived from the DynamoChartManager for LaMe_Core library core objects

from PySide2.QtCore import QObject, Signal, Slot, Property, QPointF
import numpy as np
from datetime import datetime

from dynamoChart.dynamoChartManager import DynamoChartManager
from .definitions import *


## @class LaMe_CoreChartManager
class LaMe_CoreChartManager(DynamoChartManager):

