import os

import sys

from PySide2.QtWidgets import QApplication, QGraphicsItem
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from dynamoChart.dynamoChartManager import DynamoChartManager
from testUtilities.testObject import TestObject


if __name__ == '__main__':

    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    os.environ["QT_SCALE_FACTOR"] = "1"

    chartMng = DynamoChartManager(verbose=True)
    test = TestObject()
    test.sendingIt.connect(chartMng.addSeries)

    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    ctx = engine.rootContext()
    ctx.setContextProperty("ChartMng",chartMng)
    ctx.setContextProperty("Tester",test)
    # ------------------------------------------------------------------------ #
    engine.load('testUtilities/dynamoTest.qml')
    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec_())