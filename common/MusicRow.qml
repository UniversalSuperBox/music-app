/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Nekhelesh Ramananthan <krnekhelesh@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
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

import QtQuick 2.3
import Ubuntu.Components 1.1


Row {
    anchors {
        left: parent.left
        leftMargin: units.gu(2)
        right: parent.right
        rightMargin: units.gu(2)
    }

    property alias covers: coverRow.covers
    property bool showCovers: true
    property bool isSquare: false
    property alias pressed: coverRow.pressed
    property alias column: columnComponent.sourceComponent
    property real coverSize: styleMusic.common.albumSize

    spacing: units.gu(1)

    CoverRow {
        id: coverRow
        visible: showCovers && !isSquare
        anchors {
            top: parent.top
            topMargin: units.gu(1)
        }
        count: covers.length
        covers: []
        size: coverSize
    }

    Image {
        id: coverSquare
        visible: showCovers && isSquare
        width: coverSize
        height: coverSize
        anchors {
            verticalCenter: parent.verticalCenter
            topMargin: units.gu(0.5)
            bottomMargin: units.gu(0.5)
            leftMargin: units.gu(2)
        }
        source: coverRow.count !== 0 && coverRow.covers[0] !== "" && coverRow.covers[0] !== undefined
                ? (coverRow.covers[0].art !== undefined
                   ? coverRow.covers[0].art
                   : "image://albumart/artist=" + coverRow.covers[0].author + "&album=" + coverRow.covers[0].album)
                : Qt.resolvedUrl("../images/music-app-cover@30.png")
        sourceSize.height: height
        sourceSize.width: width
        onStatusChanged: {
            if (status === Image.Error) {
                source = Qt.resolvedUrl("../images/music-app-cover@30.png")
            }
        }
    }

    Loader {
        id: columnComponent
        anchors {
            top: parent.top
            topMargin: units.gu(1)
        }
        width: !showCovers ? parent.width - parent.spacing
                           : (isSquare ? parent.width - coverSquare.width - parent.spacing
                                       : parent.width - coverRow.width - parent.spacing)

        onSourceComponentChanged: {
            for (var i=0; i < item.children.length; i++) {
                item.children[i].elide = Text.ElideRight
                item.children[i].height = units.gu(2)
                item.children[i].maximumLineCount = 1
                item.children[i].wrapMode = Text.NoWrap
                item.children[i].verticalAlignment = Text.AlignVCenter

                // binds to width so it is updated when screen size changes
                item.children[i].width = Qt.binding(function () { return width; })
            }
        }
    }
}
