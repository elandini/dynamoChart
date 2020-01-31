import QtQuick 2.10
import QtQuick.Controls 2.12
import QtQuick.Controls 1.1 as OldControls
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import "dynamoChart"

ApplicationWindow {

    id: dynamoPage
    width: 900
    height: 400
    visible: true
    // ChartMng = chart manager for the

    Pane{
        id: dynamoPane
        anchors.fill: parent
        RowLayout{
            id: testRowLO
            anchors.fill: parent

            DynamoChart{
                id: dynamoTest
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            ColumnLayout{
                id: buttonsColLO
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.maximumWidth: 70

                Item {
                    // spacer item
                    id: button1Spacer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.maximumWidth: saveParamsBtn.height
                    Pane { anchors.fill: parent; Material.background: "transparent" }
                }


                RoundButton{
                    id: playBtn
                    Material.background: Material.Lime
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumHeight: width
                    text: "P"
                }

                Item {
                    // spacer item
                    id: button2Spacer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.maximumWidth: saveParamsBtn.height
                    Pane { anchors.fill: parent; Material.background: "transparent" }
                }

                RoundButton{
                    id: stopBtn
                    Material.background: Material.Red
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumHeight: width
                    text: "S"
                }

                Item {
                    // spacer item
                    id: button3Spacer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.maximumWidth: saveParamsBtn.height
                    Pane { anchors.fill: parent; Material.background: "transparent" }
                }

            }
        }
    }
}
