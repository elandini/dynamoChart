import os

import sys

from PySide2.QtWidgets import QApplication, QGraphicsItem
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from dynamoChart.dynamoChartManager import DynamoChartManager
from testUtilities.testObject import TestObject
from testUtilities.testThread import TestThread,TestScatter


if __name__ == '__main__':

    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    os.environ["QT_SCALE_FACTOR"] = "1"

    chartMng = DynamoChartManager(verbose=True)
    test = TestObject("sandro")
    test.sendingIt.connect(chartMng.addSeries)
    stest = TestObject("sosso","scatter",4,False)
    stest.sendingIt.connect(chartMng.addSeries)
    timer = TestThread(100,"sandro",5000,0.01,100)
    timer.data.connect(chartMng.replaceSeries)
    stimer = TestScatter(10,"sosso",0.05)
    stimer.data.connect(chartMng.addPoint)

    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    ctx = engine.rootContext()
    ctx.setContextProperty("ChartMng",chartMng)
    ctx.setContextProperty("Tester",test)
    ctx.setContextProperty("STester", stest)
    ctx.setContextProperty("TTimer",timer)
    ctx.setContextProperty("STimer", stimer)
    # ------------------------------------------------------------------------ #
    engine.load('testUtilities/dynamoTest.qml')
    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec_())