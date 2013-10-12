/*
 * Copyright (C) 2013 Andrew Hayzen <ahayzen@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
 *                    Victor Thompson <victor.thompson@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import QtMultimedia 5.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1
import "settings.js" as Settings

Rectangle {
    id: musicToolbarContainer
    color: styleMusic.playerControls.backgroundColor
    height: fullHeight
    state: "minimized"
    width: parent.width
    x: parent.x

    // Properties storing the current page info
    property var currentParentPage: null
    property var currentPageStack: null
    property var currentPage: null
    property var currentTab: null

    // The current mode of the controls
    property string currentMode: currentPage === nowPlaying ? "full" : "expanded"

    // Properties for the different heights
    property int minimizedHeight: units.gu(0.5)
    property int expandedHeight: units.gu(8)
    property int fullHeight: units.gu(11)
    property int mouseAreaOffset: units.gu(2)

    // Properties and signals for the toolbar
    property string cachedState: ""
    property bool shown: false
    property int transitionDuration: 100

    // Shown/hide relevant child items depending on mode
    onCurrentModeChanged: {
        musicToolbarExpandedContainer.visible = currentMode !== "full"
        musicToolbarFullContainer.visible = currentMode === "full"

        // Update the container state if required
        if (state !== "minimized")
        {
            state = currentMode
        }
    }

    // Emit toolbarShownChanged signal when the toolbar is shown/hidden
    onShownChanged: {
        onToolbarShownChanged(shown, currentPage, currentTab);
        musicToolbar.opened = shown;
    }

    states: [
        // State for when the toolbar is hidden
        State {
            name: "hidden"
            PropertyChanges {
                target: musicToolbarContainer
                y: parent.height
            }
            PropertyChanges {
                target: musicToolbarMouseArea
                anchors.topMargin: 0
            }
            PropertyChanges {
                target: musicToolbarSmallProgressBackground
                opacity: 0
            }
            PropertyChanges {
                target: musicToolbarFullProgressMouseArea
                visible: false
            }
        },
        // State for when the toolbar is minimized
        State {
            name: "minimized"
            PropertyChanges {
                target: musicToolbarContainer
                y: parent.height - minimizedHeight
            }
            PropertyChanges {
                target: musicToolbarMouseArea
                anchors.topMargin: -mouseAreaOffset  // should allow drag from outside the item
            }
            PropertyChanges {
                target: musicToolbarSmallProgressBackground
                opacity: 1
            }
            PropertyChanges {
                target: musicToolbarFullProgressMouseArea
                visible: false
            }
        },
        // State for when the toolbar is shown
        State {
            name: "expanded"
            PropertyChanges {
                target: musicToolbarContainer
                y: parent.height - expandedHeight - minimizedHeight
            }
            PropertyChanges {
                target: musicToolbarMouseArea
                anchors.topMargin: 0
            }
            PropertyChanges {
                target: musicToolbarSmallProgressBackground
                opacity: 1
            }
            PropertyChanges {
                target: musicToolbarFullProgressMouseArea
                visible: false
            }
        },
        // State for when the toolbar is shown on the now playing page
        State {
            name: "full"
            PropertyChanges {
                target: musicToolbarContainer
                y: parent.height - fullHeight
            }
            PropertyChanges {
                target: musicToolbarMouseArea
                anchors.topMargin: 0
            }
            PropertyChanges {
                target: musicToolbarSmallProgressBackground
                opacity: 0
            }
            PropertyChanges {
                target: musicToolbarFullProgressMouseArea
                visible: true
            }
        }
    ]

    transitions: Transition {
        from: "minimized,minimized,expanded,expanded,full,full"
        to: "expanded,full,minimized,full,minimized,expanded"
        NumberAnimation {
            duration: transitionDuration
            properties: "y,opacity"
        }

        onRunningChanged: {
            musicToolbar.animating = running;
        }
    }

    /* Helper functions */

    // Disable the toolbar for this page/view (eg a dialog)
    function disableToolbar()
    {
        cachedState = state;
        state = "hidden";
    }

    // Enable the toolbar (run when closing a page that disabled it)
    function enableToolbar()
    {
        if (cachedState !== "")
        {
            state = cachedState;
            cachedState = "";
        }
    }

    // Back button has been pressed, jump up pageStack or back to parent page
    function goBack()
    {
        if (currentPageStack !== null)
        {
            currentPageStack.pop(currentPage)
        }
        else if (currentParentPage !== null)
        {
            currentParentPage.visible = false  // force switch
            currentPage.visible = false
            currentParentPage.visible = true
        }
    }

    // Hide the toolbar
    function hideToolbar()
    {
        musicToolbarContainer.state = "minimized";
        shown = false;
    }

    // Set the current page, and any parent/stacks
    function setPage(childPage, parentPage, pageStack)
    {
        currentPage = childPage;
        currentParentPage = parentPage === undefined ? null : parentPage;
        currentPageStack = pageStack === undefined ? null : pageStack;
    }

    // Show the toolbar
    function showToolbar()
    {
        musicToolbarContainer.state = currentPage === nowPlaying ? "full" : "expanded";
        shown = true;
    }

    /* Mouse area to block events going to items under the toolbar */
    MouseArea {
        anchors.fill: parent
        onClicked: mouse.accepted = true
    }

    /* Expanded toolbar */
    Rectangle {
        id: musicToolbarExpandedContainer
        anchors.left: parent.left
        anchors.top: musicToolbarSmallProgressBackground.bottom
        height: expandedHeight
        width: parent.width

        Rectangle {
            id: musicToolbarPlayerControls
            anchors.fill: parent
            color: styleMusic.playerControls.backgroundColor
            state: trackQueue.isEmpty === true ? "disabled" : "enabled"

            states: [
                State {
                    name: "disabled"
                    PropertyChanges {
                        target: disabledPlayerControlsGroup
                        visible: true
                    }
                    PropertyChanges {
                        target: enabledPlayerControlsGroup
                        visible: false
                    }
                },
                State {
                    name: "enabled"
                    PropertyChanges {
                        target: disabledPlayerControlsGroup
                        visible: false
                    }
                    PropertyChanges {
                        target: enabledPlayerControlsGroup
                        visible: true
                    }
                }
            ]

            Rectangle {
                id: disabledPlayerControlsGroup
                anchors.fill: parent
                color: "transparent"
                visible: trackQueue.isEmpty === true

                Label {
                    id: noSongsInQueueLabel
                    anchors.left: parent.left
                    anchors.margins: units.gu(1)
                    anchors.top: parent.top
                    color: styleMusic.playerControls.labelColor
                    text: i18n.tr("No songs queued")
                    fontSize: "large"
                }

                Label {
                    id: tabToStartPlayingLabel
                    color: styleMusic.playerControls.labelColor
                    anchors.left: parent.left
                    anchors.margins: units.gu(1)
                    anchors.top: noSongsInQueueLabel.bottom
                    text: i18n.tr("Tap on a song to start playing")
                }
            }

            Rectangle {
                id: enabledPlayerControlsGroup
                anchors.fill: parent
                color: "transparent"
                visible: trackQueue.isEmpty === false

                /* Settings button */
                UbuntuShape {
                    id: playerControlsSettings
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: units.gu(6)

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        height: units.gu(3)
                        source: Qt.resolvedUrl("images/settings.png")
                        width: height
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.debug('Debug: Show settings')
                            PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                            {
                                                title: i18n.tr("Settings")
                                            } )
                        }
                    }
                }

                /* Play/Pause button TODO: image and colours needs updating */
                Rectangle {
                    id: playerControlsPlayButton
                    anchors.right: playerControlsSettings.left
                    anchors.rightMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true
                    color: "#222"
                    height: units.gu(6)
                    radius: height / 2
                    width: height

                    Rectangle {
                        id: playerControlsPlayInnerCircle
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        antialiasing: true
                        color: "#444"
                        height: units.gu(3.5)
                        radius: height / 2
                        width: height
                        UbuntuShape {
                            anchors.fill: parent
                            objectName: "playshape"  // objectName doesn't work on Rectangle?
                            image: Image {
                                id: playindicator
                                anchors.fill: parent
                                opacity: .7
                                source: player.playbackState === MediaPlayer.PlayingState ?
                                          "images/pause.png" : "images/play.png"
                            }
                        }

                    }
                    MouseArea {
                        anchors.fill: parent

                        function inCircle(x, y) {
                            /*
                              Function that returns true if the mouse is inside the circle
                                Length = root((y2-y1)^2 + (x2-x1)^2)
                             */
                            x = Math.pow(x - (width / 2), 2);
                            y = Math.pow(y - (height / 2), 2);

                            return Math.pow((x + y), 0.5) <= parent.radius;
                        }

                        onClicked: {
                            var accepted = inCircle(mouse.x, mouse.y);

                            mouse.accepted = accepted;

                            if (accepted)
                            {
                                if (player.playbackState === MediaPlayer.PlayingState)
                                {
                                    player.pause()
                                }
                                else
                                {
                                    player.play()
                                }
                            }
                        }
                    }
                }

                /* Back button to go up pageStack */
                UbuntuShape {
                    id: playerControlBackButton
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    width: units.gu(6)
                    visible: currentPageStack !== null && currentParentPage !== null

                    Image {
                        height: units.gu(3)
                        source: Qt.resolvedUrl("images/back.svg")
                        width: height
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            goBack();
                        }
                    }
                }

                /* Container holding the labels for the toolbar */
                Rectangle {
                    id: playerControlLabelContainer
                    anchors.bottom: parent.bottom
                    anchors.left: playerControlBackButton.right
                    anchors.right: playerControlsPlayButton.left
                    anchors.top: parent.top
                    color: "transparent"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            nowPlaying.visible = true
                        }
                    }

                    /* Title of track */
                    Label {
                        id: playerControlsTitle
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        color: styleMusic.playerControls.labelColor
                        elide: Text.ElideRight
                        fontSize: "medium"
                        objectName: "playercontroltitle"
                        text: mainView.currentTracktitle === "" ? mainView.currentFile : mainView.currentTracktitle
                    }

                    /* Artist of track */
                    Label {
                        id: playerControlsArtist
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        anchors.top: playerControlsTitle.bottom
                        color: styleMusic.playerControls.labelColor
                        elide: Text.ElideRight
                        fontSize: "small"
                        text: mainView.currentArtist
                    }

                    /* Album of track */
                    Label {
                        id: playerControlsAlbum
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        anchors.top: playerControlsArtist.bottom
                        color: styleMusic.playerControls.labelColor
                        elide: Text.ElideRight
                        fontSize: "small"
                        text: mainView.currentAlbum
                    }
                }
            }
        }
    }

    /* Full toolbar */
    Rectangle {
        id: musicToolbarFullContainer
        anchors.left: parent.left
        anchors.top: parent.top
        color: styleMusic.toolbar.fullBackgroundColor
        height: fullHeight
        width: parent.width

        /* Buttons component */
        Rectangle {
            id: musicToolbarFullButtonsContainer
            anchors.left: parent.left
            anchors.top: musicToolbarFullProgressContainer.bottom
            color: "transparent"
            height: parent.height - musicToolbarFullProgressContainer.height
            width: parent.width

            /* Shuffle button */
            UbuntuShape {
                id: nowPlayingShuffleButton
                anchors.right: nowPlayingPreviousButton.left
                anchors.rightMargin: units.gu(1)
                anchors.verticalCenter: parent.verticalCenter
                height: units.gu(6)
                width: height
                color: "#000000"

                Image {
                    id: shuffleIcon
                    height: units.gu(3)
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "images/shuffle.png"
                    opacity: Settings.getSetting("shuffle") === "1" ? 1 : .25
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        // Invert shuffle settings
                        Settings.setSetting("shuffle", !(Settings.getSetting("shuffle") === "1"))
                        mainView.random = Settings.getSetting("shuffle") === "1"
                        shuffleIcon.opacity = Settings.getSetting("shuffle") === "1" ? 1 : .25
                    }
                }
            }

            /* Previous button */
            UbuntuShape {
                id: nowPlayingPreviousButton
                anchors.right: nowPlayingPlayButton.left
                anchors.rightMargin: units.gu(1)
                anchors.verticalCenter: parent.verticalCenter
                height: units.gu(6)
                width: height

                image: Image {
                    id: nowPlayingPreviousIndicator
                    anchors.fill: parent
                    source: "images/back.png"
                    opacity: .7
                }

                MouseArea {
                    anchors.fill: parent
                    id: nowPlayingPreviousMouseArea
                    onClicked:
                    {
                        previousSong()
                    }
                }
            }

            /* Play/Pause button */
            Rectangle {
                id: nowPlayingPlayButton
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                antialiasing: true
                color: styleMusic.toolbar.fullOuterPlayCircleColor
                height: units.gu(12)
                radius: height / 2
                width: height

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true
                    color: styleMusic.toolbar.fullInnerPlayCircleColor
                    height: units.gu(8)
                    radius: height / 2
                    width: height

                    UbuntuShape {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        height: units.gu(6)
                        width: height
                        image: Image {
                            id: nowPlayingPlayIndicator
                            opacity: .7
                            source: player.playbackState === MediaPlayer.PlayingState ?
                                      "images/pause.png" : "images/play.png"
                            width: height
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        id: nowPlayingPlayMouseArea

                        function inCircle(x, y) {
                            /*
                              Function that returns true if the mouse is inside the circle
                                Length = root((y2-y1)^2 + (x2-x1)^2)
                             */
                            x = Math.pow(x - (width / 2), 2);
                            y = Math.pow(y - (height / 2), 2);

                            return Math.pow((x + y), 0.5) <= parent.radius;
                        }

                        onClicked:
                        {
                            if (!inCircle(mouse.x, mouse.y))
                            {
                                return;
                            }

                            if (player.playbackState === MediaPlayer.PlayingState)
                            {
                                player.pause()
                            }
                            else
                            {
                                player.play()
                            }
                        }
                    }
                }
            }

            /* Next button */
            UbuntuShape {
                id: nowPlayingNextButton
                anchors.left: nowPlayingPlayButton.right
                anchors.leftMargin: units.gu(1)
                anchors.verticalCenter: parent.verticalCenter
                height: units.gu(6)
                objectName: "forwardshape"
                width: height

                image: Image {
                    id: nowPlayingNextIndicator
                    anchors.fill: parent
                    source: "images/forward.png"
                    opacity: .7
                }

                MouseArea {
                    anchors.fill: parent
                    id: nowPlayingNextMouseArea
                    onClicked:
                    {
                        nextSong()
                    }
                }
            }

            /* Repeat button */
            UbuntuShape {
                id: nowPlayingRepeatButton
                anchors.left: nowPlayingNextButton.right
                anchors.leftMargin: units.gu(1)
                anchors.verticalCenter: parent.verticalCenter
                height: units.gu(6)
                width: height
                color: "#000000"

                Image {
                    id: repeatIcon
                    height: units.gu(3)
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "images/repeat.png"
                    verticalAlignment: Text.AlignVCenter
                    opacity: Settings.getSetting("repeat") === "1" ? 1 : .25
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        // Invert repeat settings
                        Settings.setSetting("repeat", !(Settings.getSetting("repeat") === "1"))
                        repeatIcon.opacity = Settings.getSetting("repeat") === "1" ? 1 : .25
                    }
                }
            }
        }

        /* Progress bar component */
        Rectangle {
            id: musicToolbarFullProgressContainer
            anchors.left: parent.left
            anchors.top: parent.top
            color: styleMusic.toolbar.fullBackgroundColor
            height: units.gu(3)
            width: parent.width

            /* Position label */
            Label {
                id: musicToolbarFullPositionLabel
                anchors.left: parent.left
                anchors.top: parent.top
                color: styleMusic.nowPlaying.labelColor
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                text: player.positionStr
                verticalAlignment: Text.AlignVCenter
                width: units.gu(6)
            }

            /* Progress bar */
            Rectangle {
                id: musicToolbarFullProgressBarContainer
                anchors.left: musicToolbarFullPositionLabel.right
                anchors.right: musicToolbarFullDurationLabel.left
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                height: units.gu(1);
                state: trackQueue.isEmpty === true ? "disabled" : "enabled"

                states: [
                    State {
                        name: "disabled"
                        PropertyChanges {
                            target: musicToolbarFullProgressMouseArea
                            enabled: false
                        }
                        PropertyChanges {
                            target: musicToolbarFullProgressTrough
                            visible: false
                        }
                        PropertyChanges {
                            target: musicToolbarFullProgressHandle
                            visible: false
                        }
                    },
                    State {
                        name: "enabled"
                        PropertyChanges {
                            target: musicToolbarFullProgressMouseArea
                            enabled: true
                        }
                        PropertyChanges {
                            target: musicToolbarFullProgressTrough
                            visible: true
                        }
                        PropertyChanges {
                            target: musicToolbarFullProgressHandle
                            visible: true
                        }
                    }
                ]

                // Connection from positionChanged signal
                function updatePosition(position, duration)
                {
                    if (player.seeking == false)
                    {
                        musicToolbarFullProgressHandle.x = ((position / duration) * musicToolbarFullProgressBarContainer.width)
                                - musicToolbarFullProgressHandle.width / 2;
                    }
                }

                Component.onCompleted: {
                    // Connect to signal from MediaPlayer
                    player.positionChange.connect(updatePosition)
                }

                // Black background behind the progress bar
                Rectangle {
                    id: musicToolbarFullProgressBackground
                    anchors.verticalCenter: parent.verticalCenter;
                    color: styleMusic.toolbar.fullProgressBackgroundColor;
                    height: parent.height;
                    radius: units.gu(0.5)
                    width: parent.width;
                }

                // The orange fill of the progress bar
                Rectangle {
                    id: musicToolbarFullProgressTrough
                    anchors.verticalCenter: parent.verticalCenter;
                    antialiasing: true
                    color: styleMusic.toolbar.fullProgressTroughColor;
                    height: parent.height;
                    radius: units.gu(0.5)
                    width: musicToolbarFullProgressHandle.x + (height / 2);  // +radius
                }

                // The current position (handle) of the progress bar
                Rectangle {
                    id: musicToolbarFullProgressHandle
                    anchors.verticalCenter: musicToolbarFullProgressBackground.verticalCenter
                    antialiasing: true
                    color: styleMusic.nowPlaying.progressHandleColor
                    height: units.gu(1.5)
                    radius: height / 2
                    width: height

                    // On X change update the position string
                    onXChanged: {
                        var fraction = (x + (width / 2)) / parent.width;
                        player.positionStr = __durationToString(fraction * player.duration);
                    }

                    transitions: Transition {
                        NumberAnimation {
                            properties: "x"
                            duration: 1000
                        }
                    }
                }
            }

            /* Duration label */
            Label {
                id: musicToolbarFullDurationLabel
                anchors.right: parent.right
                anchors.top: parent.top
                color: styleMusic.nowPlaying.labelColor
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                text: player.durationStr
                verticalAlignment: Text.AlignVCenter
                width: units.gu(6)
            }

            /* Border at the bottom */
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                color: "#000"
                height: units.gu(0.2)
                opacity: 0.1
            }
        }
    }

    /* Object which provides the progress bar when toolbar is minimized */
    Rectangle {
        id: musicToolbarSmallProgressBackground
        anchors.left: parent.left
        anchors.top: parent.top
        color: styleMusic.common.black
        height: minimizedHeight
        width: parent.width

        Rectangle {
            id: musicToolbarSmallProgressHint
            anchors.left: parent.left
            anchors.top: parent.top
            color: styleMusic.nowPlaying.progressForegroundColor
            height: parent.height
            width: 0

            function updatePosition(position, duration)
            {
                musicToolbarSmallProgressHint.width = (position / duration) * musicToolbarSmallProgressBackground.width
            }

            Component.onCompleted: {
                player.positionChange.connect(updatePosition)
            }
        }
    }

    /* Object which captures mouse drags to show/hide the toolbar */
    MouseArea {
        id: musicToolbarMouseArea
        anchors.fill: parent

        property bool changed: false
        property int startContainerY: 0
        property int startMouseY: 0

        // Settings for dragging the container
        drag.axis: Drag.YAxis
        drag.maximumY: musicToolbarContainer.parent.height - minimizedHeight
        drag.minimumY: currentMode === "full" ?
                           musicToolbarContainer.parent.height - fullHeight :
                           musicToolbarContainer.parent.height - expandedHeight - minimizedHeight
        drag.target: musicToolbarContainer

        propagateComposedEvents: true
        onClicked: mouse.accepted = changed  // pass clicked evented to children unless changed (YAxis)

        onMouseYChanged: {
            // Mouse has been accepted with YAxis changed and set changed to true
            mouse.accepted = true;
            changed = true;
        }

        onPressAndHold: {
            // If the item hasn't moved then run the hint animation
            if (musicToolbarContainer.y === startContainerY)
            {
                musicToolbarContainerHintAnimation.start();
                mouse.accepted = true;  // mouse has been accepted
            }
            else
            {
                mouse.accepted = false;
            }
        }

        onPressed: {
            mouse.accepted = false;  // mouse not accepted yet

            // Record starting positions for later
            startContainerY = musicToolbarContainer.y;
            startMouseY = mouse.y;
        }

        onReleased: {
            mouse.accepted = changed;  // mouse is accepted if the YAxis has changed
            changed = false;  // reset changed

            // fix for flicker on first run (needs a value to have been set?)
            musicToolbarContainer.y = musicToolbarContainer.y;

            var diff = musicToolbarContainer.y - startContainerY;

            if (diff > units.gu(3))
            {
                hideToolbar();
            }
            else if (diff < -units.gu(3))
            {
                showToolbar();
            }
            else
            {
                musicToolbarContainerReset.start();
            }
        }

        // On pressandhold reveal part of the toolbar as a hint
        NumberAnimation {
            id: musicToolbarContainerHintAnimation
            target: musicToolbarContainer
            property: "y"
            duration: musicToolbarContainer.transitionDuration
            to: musicToolbarContainer.parent.height - minimizedHeight - units.gu(1.5)
        }

        // Animation to reset the toolbar if it hasn't been dragged far enough
        NumberAnimation {
            id: musicToolbarContainerReset
            target: musicToolbarContainer
            property: "y"
            duration: musicToolbarContainer.transitionDuration
            to: musicToolbarMouseArea.startContainerY
        }
    }

    /* Mouse events for the progress bar
       is after musicToolbarMouseArea so that it captures mouse events for dragging */
    MouseArea {
        id: musicToolbarFullProgressMouseArea
        height: units.gu(2)
        width: musicToolbarFullProgressBarContainer.width
        x: musicToolbarFullProgressBarContainer.x
        y: musicToolbarFullProgressBarContainer.y

        drag.axis: Drag.XAxis
        drag.minimumX: -(musicToolbarFullProgressHandle.width / 2)
        drag.maximumX: musicToolbarFullProgressBarContainer.width - (musicToolbarFullProgressHandle.width / 2)
        drag.target: musicToolbarFullProgressHandle

        onPressed: {
            player.seeking = true;
            // Jump the handle to the current mouse position
            musicToolbarFullProgressHandle.x = mouse.x - (musicToolbarFullProgressHandle.width / 2);
        }

        onReleased: {
            var fraction = mouse.x / musicToolbarFullProgressBarContainer.width;

            // Limit the bounds of the fraction
            fraction = fraction < 0 ? 0 : fraction
            fraction = fraction > 1 ? 1 : fraction

            player.seek((fraction) * player.duration);
            player.seeking = false;
        }
    }
}