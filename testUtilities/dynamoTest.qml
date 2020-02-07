import QtQuick 2.10
import QtQuick.Controls 2.12
import QtQuick.Controls 1.1 as OldControls
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtCharts 2.3
import "../dynamoChart"

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
                manager: ChartMng
                Component.onCompleted: function(){
                    dynamoTest.managerAssociation();
                }
            }

            ColumnLayout{
                id: buttonsColLO
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.maximumWidth: 70

                RoundButton{
                    id: scatterBtn
                    Material.background: Material.Blue
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumHeight: width
                    property bool start: true
                    text: "S"
                    onClicked: function(){
                        if(start){
                            STimer.startTimer();
                        }
                        else{
                            STimer.stopTimer();
                        }
                        start = !start;
                    }
                }

                Item {
                    // spacer item
                    id: button1Spacer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Pane { anchors.fill: parent; Material.background: "transparent" }
                }


                RoundButton{
                    id: replaceBtn
                    Material.background: Material.Lime
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumHeight: width
                    property bool start: true
                    text: "R"
                    onClicked: function(){
                        if(start){
                            TTimer.startTimer();
                        }
                        else{
                            TTimer.stopTimer();
                        }
                        start = !start;
                    }
                }

                Item {
                    // spacer item
                    id: button2Spacer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Pane { anchors.fill: parent; Material.background: "transparent" }
                }

                RoundButton{
                    id: addBtn
                    Material.background: Material.Red
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumHeight: width
                    text: "AL"
                    onClicked: function(){
                        Tester.sendIt(0);
                        dynamoTest.setState("filled");
                    }
                }

                Item {
                    // spacer item
                    id: button3Spacer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Pane { anchors.fill: parent; Material.background: "transparent" }
                }

                RoundButton{
                    id: addScatterBtn
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumHeight: width
                    text: "AS"
                    onClicked: function(){
                        STester.sendIt(0);
                        ChartMng.setStripChart({"doStrip":true,"points":100})
                        dynamoTest.setState("filled");
                    }
                }
                Item {
                    // spacer item
                    id: button4Spacer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Pane { anchors.fill: parent; Material.background: "transparent" }
                }

                RoundButton{
                    id: clearBtn
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumHeight: width
                    text: "C"
                    onClicked: function(){
                        ChartMng.clear();
                    }
                }
            }
        }
    }
}
