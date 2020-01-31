import os

import sys

from PySide2.QtWidgets import QApplication, QGraphicsItem
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from dynamoChart.dynamoChartManager import DynamoChartManager


if __name__ == '__main__':

    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    os.environ["QT_SCALE_FACTOR"] = "1"

    chartMng = DynamoChartManager(verbose=True)

    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    ctx = engine.rootContext()
    ctx.setContextProperty("ChartMng",chartMng)
    # ------------------------------------------------------------------------ #
    engine.load('dynamoTest.qml')
    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec_())