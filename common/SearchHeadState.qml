/*
 * Copyright (C) 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
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

PageHeadState {
    id: headerState
    name: "search"
    head: thisPage.head
    backAction: Action {
        id: leaveSearchAction
        text: "back"
        iconName: "back"
        onTriggered: {
            thisPage.state = "default"
            searchField.text = ""
        }
    }
    contents: TextField {
        id: searchField
        anchors {
            left: parent ? parent.left : undefined
            right: parent ? parent.right : undefined
            rightMargin: units.gu(2)
        }
        color: styleMusic.common.black
        hasClearButton: true
        inputMethodHints: Qt.ImhNoPredictiveText
        placeholderText: i18n.tr("Search music")

        onParentChanged: {
            if (parent === null) {
                text = ""
            }
        }

        onVisibleChanged: {
            if (visible) {
                forceActiveFocus()
            }
        }

        // Use the page onVisible as the text field goes visible=false when switching states
        // This is used when popping from the pageStack and returning back to a page with search
        Connections {
            target: thisPage
            onVisibleChanged: {
                if (!visible) {
                    searchField.text = ""
                    thisPage.state = "default"
                }
            }
        }
    }

    property Page thisPage
    property alias query: searchField.text
}
