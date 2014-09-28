/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
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
import Ubuntu.Components.Popups 1.0
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import QtGraphicalEffects 1.0
import "settings.js" as Settings
import "playlists.js" as Playlists
import "common"

MusicPage {
    id: mainpage
    objectName: "albumsPage"
    title: i18n.tr("Albums")

    // TODO: This ListView is empty and causes the header to get painted with the desired background color because the
    //       page is now vertically flickable.
    ListView {
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
    }

    CardView {
        id: albumlist
        anchors {
            topMargin: mainView.header.height
        }

        model: SortFilterModel {
            id: albumsModelFilter
            property alias rowCount: albumsModel.rowCount
            model: AlbumsModel {
                id: albumsModel
                store: musicStore
            }
            sort.property: "title"
            sort.order: Qt.AscendingOrder
        }
        delegate: albumDelegate

        Component {
            id: albumDelegate
            Card {
                id: albumItem
                imageSource: model.art
                objectName: "albumsPageGridItem" + index
                primaryText: model.title
                secondaryText: model.artist

                onClicked: {
                    songsPage.album = model.title;
                    songsPage.covers = [{art: model.art}]
                    songsPage.genre = undefined
                    songsPage.isAlbum = true
                    songsPage.line1 = model.artist
                    songsPage.line2 = model.title
                    songsPage.title = i18n.tr("Album")

                    mainPageStack.push(songsPage)
                }
            }
        }
    }
}


