import os

import sys

from PySide2.QtWidgets import QApplication, QGraphicsItem
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from dynamoChart.dynamoChartManager import DynamoChartManager
from testUtilities.testObject import TestObject
from testUtilities.testThread import TestThread


if __name__ == '__main__':

    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    os.environ["QT_SCALE_FACTOR"] = "1"

    chartMng = DynamoChartManager(verbose=True)
    test = TestObject("sandro")
    test.sendingIt.connect(chartMng.addSeries)
    timer = TestThread(0.01,"sandro",1000,0.001,1000)
    timer.data.connect(chartMng.replaceSeries)

    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    ctx = engine.rootContext()
    ctx.setContextProperty("ChartMng",chartMng)
    ctx.setContextProperty("Tester",test)
    ctx.setContextProperty("TTimer",timer)
    # ------------------------------------------------------------------------ #
    engine.load('testUtilities/dynamoTest.qml')
    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec_())