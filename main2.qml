import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtWebEngine 1.9
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 16
        switchHeight: Kirigami.Units.gridUnit * 23

            fullRepresentation: ColumnLayout {
                Layout.minimumWidth: root.switchWidth
                Layout.minimumHeight: root.switchHeight

                // 🔹 Navigation Bar
                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents3.Button {
                        icon.name: "go-previous-symbolic"
                        text: ""
                        onClicked: currentWebView()?.goBack()
                        enabled: currentWebView()?.canGoBack || false
                    }
                    PlasmaComponents3.Button {
                        icon.name: "go-next-symbolic"
                        text: ""
                        onClicked: currentWebView()?.goForward()
                        enabled: currentWebView()?.canGoForward || false
                    }
                    PlasmaComponents3.TextField {
                        id: addressBar
                        Layout.fillWidth: true
                        placeholderText: "Enter URL"

                        background: Item {
                            Rectangle {
                                id: progressBar
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (currentWebView()?.loadingProgress || 0) / 100  // Fill based on progress
                                color: PlasmaCore.Theme.highlightColor  // Use theme color
                                opacity: 0.4  // Start slightly visible
                                radius: 3

                                Behavior on width { NumberAnimation { duration: 200 } }  // Smooth width animation
                                Behavior on opacity { NumberAnimation { duration: 300 } }  // Smooth fade-out
                            }

                            SequentialAnimation {
                                id: progressBarAnim
                                PropertyAnimation {
                                    target: progressBar
                                    property: "opacity"
                                    to: 0
                                    duration: 400  // Fade out smoothly when loading is complete
                                }
                            }
                        }


                        onAccepted: {
                            var url = text.trim();
                            if (!url.startsWith("http://") && !url.startsWith("https://")) {
                                url = "https://" + url;
                            }
                            currentWebView().url = url;
                        }
                    }

                    PlasmaComponents3.Button {
                        icon.name: "view-refresh-symbolic"
                        text: ""
                        onClicked: currentWebView()?.reload()
                    }
                }

                // 🔹 Tab Bar with Tab Numbers
                RowLayout {
                    id: tabBar
                    Layout.fillWidth: true

                    Repeater {
                        model: tabModel
                        PlasmaComponents3.Button {
                            Layout.margins: 5
                            onClicked: tabModel.currentIndex = index

                            RowLayout {
                                spacing: 5

                                // ✅ Display Tab Number
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 5
                                    color: index === tabModel.currentIndex ? PlasmaCore.Theme.highlightColor : "lightgray"  // Highlight selected tab

                                    PlasmaComponents3.Label {
                                        anchors.centerIn: parent
                                        text: index + 1  // Show tab number
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        color: PlsamaCore.Theme.textColor
                                    }
                                }

                                // ✅ Show Tab Title
                                PlasmaComponents3.Label {
                                    text: modelData.title
                                }
                            }
                        }
                    }

                    // ✅ New Tab Button
                    PlasmaComponents3.Button {
                        text: "+"
                        onClicked: addNewTab("https://www.kde.org/")
                    }
                }

                // 🔹 Web Views (Each Tab is Independent)
                StackLayout {
                    id: tabStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabModel.currentIndex

                    Repeater {
                        model: tabModel
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            WebEngineView {
                                id: webview
                                anchors.fill: parent
                                url: modelData.url
                                property int loadingProgress: 0  // Track progress

                                onLoadingChanged: {
                                    if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
                                        loadingProgress = 100;  // Page fully loaded
                                        progressBarAnim.start();  // Start animation to hide bar
                                    } else if (loadRequest.status === WebEngineLoadRequest.LoadStartedStatus) {
                                        loadingProgress = 0;  // Reset progress on new page load
                                        progressBar.opacity = 0.4;  // Make sure bar is visible
                                    }
                                }

                                onLoadProgressChanged: {
                                    loadingProgress = loadProgress;  // Update progress dynamically
                                }
                            }


                        }
                    }
                }

                // ✅ Tab Data (Stores Title and URL)
                ListModel {
                    id: tabModel
                    property int currentIndex: 0
                }

                // ✅ Function to Get Current Active WebView
                function currentWebView() {
                    if (tabStack.count > 0 && tabModel.currentIndex >= 0) {
                        let currentTab = tabStack.children[tabModel.currentIndex];
                        if (currentTab && currentTab.children.length > 0) {
                            return currentTab.children[0];  // Returns the active WebEngineView
                        }
                    }
                    return null;
                }


                // ✅ Function to Add New Tab
                function addNewTab(url) {
                    tabModel.append({
                        title: "New Tab " + (tabModel.count + 1),
                                    url: url
                    });
                    tabModel.currentIndex = tabModel.count - 1;
                }

                // ✅ Load First Tab Automatically
                Component.onCompleted: addNewTab("https://www.kde.org/")
            }
}
