# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""music-app tests and emulators - top level package."""
from ubuntuuitoolkit import MainView, UbuntuUIToolkitCustomProxyObjectBase
from time import sleep


class MusicAppException(Exception):
    """Exception raised when there's an error in the Music App."""


def click_object(func):
    """Wrapper which clicks the returned object"""
    def func_wrapper(self, *args):
        return self.pointing_device.click_object(func(self, *args))

    return func_wrapper


class MusicApp(object):
    """Autopilot helper object for the Music application."""

    def __init__(self, app_proxy):
        self.app = app_proxy
        self.main_view = self.app.wait_select_single(MainView)
        self.player = self.app.select_single(Player, objectName='player')

    def get_now_playing_page(self):
        return self.app.wait_select_single(MusicNowPlaying,
                                           objectName="nowPlayingPage")

    def get_add_to_playlist_page(self):
        return self.app.wait_select_single(MusicaddtoPlaylist,
                                           objectName="addToPlaylistPage")

    def get_songs_page(self):
        return self.app.wait_select_single(SongsPage, objectName="songsPage")

    def get_toolbar(self):
        return self.app.select_single(MusicToolbar,
                                      objectName="musicToolbarObject")

    def get_tracks_page(self):
        """Open the Tracks tab.

        :return: The autopilot custom proxy object for the TracksPage.

        """
        self.main_view.switch_to_tab('tracksTab')

        return self.main_view.select_single(
            Page11, objectName='tracksPage')

    @property
    def loaded(self):
        return (not self.main_view.select_single("ActivityIndicator",
                objectName="LoadingSpinner").running and
                self.main_view.select_single("*", "allSongsModel").populated)

    def populate_queue(self):
        tracksPage = self.get_tracks_page()  # switch to track tab

        # get and click to play first track
        track = tracksPage.get_track(0)
        self.app.pointing_device.click_object(track)

        # TODO: when using bottom edge wait for .isReady on tracksPage

        # wait for now playing page to be visible
        self.get_now_playing_page().visible.wait_for(True)


class Page(UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for Pages."""
    def __init__(self, *args):
        super(Page, self).__init__(*args)
        # XXX we need a better way to keep reference to the main view.
        # --elopio - 2014-01-31
        self.main_view = self.get_root_instance().select_single(MainView)


class MusicPage(Page):
    def __init__(self, *args):
        super(Page, self).__init__(*args)


# FIXME: Represents MusicTracks related to bug 1341671 and bug 1337004
class Page11(MusicPage):
    """ Autopilot helper for the tracks page """
    def __init__(self, *args):
        super(MusicPage, self).__init__(*args)

    def get_track(self, i):
        return (self.wait_select_single(ListItemWithActions,
                objectName="tracksTabListItem" + str(i)))


class Player(UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for Player"""


class MusicNowPlaying(MusicPage):
    """ Autopilot helper for now playing page """
    def __init__(self, *args):
        super(MusicPage, self).__init__(*args)

    def get_count(self):
        return self.select_single("QQuickListView",
                                  objectName="nowPlayingQueueList").count

    def get_track(self, i):
        return (self.wait_select_single(ListItemWithActions,
                objectName="nowPlayingListItem" + str(i)))


class MusicaddtoPlaylist(MusicPage):
    """ Autopilot helper for add to playlist page """
    def __init__(self, *args):
        super(MusicPage, self).__init__(*args)

        self.visible.wait_for(True)

    def click_new_playlist_action(self):
        self.get_header().click_action_button("newPlaylistButton")

    @click_object
    def click_new_playlist_dialogue_create_button(self):
        return self.wait_select_single(
            "Button", objectName="newPlaylistDialog_createButton")

    @click_object
    def click_playlist(self, i):
        return self.get_playlist(i)

    def get_count(self):
        return self.wait_select_single(
            "QQuickListView", objectName="addToPlaylistListView").count

    def get_playlist(self, i):
        return (self.wait_select_single("Standard",
            objectName="addToPlaylistListItem" + str(i)))

    def type_new_playlist_dialogue_name(self, text):  # TODO: improve
        field = self.wait_select_single(
            "TextField", objectName="playlistnameTextfield")
        field.focus.wait_for(True)

        self.keyboard.type("myPlaylist")

    @click_object
    def set_focus_to_new_playlist_dialog_name_textfield(self):
        return self.wait_select_single(
            "TextField", objectName="playlistnameTextfield")


class SongsPage(MusicPage):
    """ Autopilot helper for the songs page """
    def __init__(self, *args):
        super(MusicPage, self).__init__(*args)

        self.visible.wait_for(True)

    @click_object
    def click_track(self, i):
        return self.get_track(i)

    def get_header_artist_label(self):
        return self.wait_select_single("Label",
            objectName="songsPageHeaderAlbumArtist")

    def get_track(self, i):
        return (self.wait_select_single(ListItemWithActions,
                objectName="songsPageListItem" + str(i)))


class MusicToolbar(UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for the toolbar

    expanded - refers to things when the toolbar is in its smaller state
    full - refers to things when the toolbar is in its larger state
    """
    def __init__(self, *args):
        super(MusicToolbar, self).__init__(*args)

        root = self.get_root_instance()
        self.player = root.select_single(Player, objectName="player")

    @click_object
    def click_small_play_button(self):
        return self.wait_select_single("*", objectName="smallPlayShape")

    @click_object
    def click_forward_button(self):
        return self.wait_select_single("*", objectName="forwardShape")

    @click_object
    def click_play_button(self):
        return self.wait_select_single("*", objectName="playShape")

    @click_object
    def click_previous_button(self):
        return self.wait_select_single("*", objectName="previousShape")

    @click_object
    def click_repeat_button(self):
        return self.wait_select_single("*", objectName="repeatShape")

    @click_object
    def click_shuffle_button(self):
        return self.wait_select_single("*", objectName="shuffleShape")

    def seek_to(self, percentage):
        progress_bar = self.wait_select_single(
            "*", objectName="progressBarShape")

        x1, y1, width, height = progress_bar.globalRect
        y1 += height // 2

        x2 = x1 + int(width * percentage / 100)

        self.pointing_device.drag(x1, y1, x2, y1)

    def set_repeat(self, state):
        if self.player.repeat != state:
            self.click_repeat_button()

        self.player.repeat.wait_for(state)

    def set_shuffle(self, state):
        if self.player.shuffle != state:
            self.click_shuffle_button()

        self.player.shuffle.wait_for(state)

    def show(self):
        self.pointing_device.move_to_object(self)

        x1, y1 = self.pointing_device.position()

        y1 -= (self.height / 2) + 1  # get position at top of toolbar

        self.pointing_device.drag(x1, y1, x1, y1 - self.fullHeight)


class ListItemWithActions(UbuntuUIToolkitCustomProxyObjectBase):
    @click_object
    def click_add_to_playlist_action(self):
        return self.wait_select_single(objectName="addToPlaylistAction")

    @click_object
    def click_add_to_queue_action(self):
        return self.wait_select_single(objectName="addToQueueAction")

    @click_object
    def confirm_removal(self):
        return self.wait_select_single(objectName="swipeDeleteAction")

    def get_label_text(self, name):
        return self.wait_select_single(objectName=name).text

    def swipe_reveal_actions(self):
        x, y, width, height = self.globalRect
        start_x = x + (width * 0.8)
        stop_x = x + (width * 0.2)
        start_y = stop_y = y + (height // 2)

        self.pointing_device.drag(start_x, start_y, stop_x, stop_y)

    def swipe_to_delete(self):
        x, y, width, height = self.globalRect
        start_x = x + (width * 0.2)
        stop_x = x + (width * 0.8)
        start_y = stop_y = y + (height // 2)

        self.pointing_device.drag(start_x, start_y, stop_x, stop_y)


class MainView(MainView):
    """Autopilot custom proxy object for the MainView."""
    retry_delay = 0.2

    def __init__(self, *args):
        super(MainView, self).__init__(*args)
        self.visible.wait_for(True)

        # wait for activity indicator to stop spinning
        spinner = self.wait_select_single("ActivityIndicator",
                                          objectName="LoadingSpinner")
        spinner.running.wait_for(False)

    def get_albumstab(self):
        return self.select_single("Tab", objectName="albumstab")

    def get_albums_albumartist_list(self):
        return self.select_many("Label", objectName="albums-albumartist")

    def get_albums_albumartist(self, artistName):
        albumartistList = self.get_albums_albumartist_list()
        for item in albumartistList:
            if item.text == artistName:
                return item

    def get_artist_page_artist(self):
        return self.wait_select_single("Label",
                                       objectName="artistpage-albumartist")

    def get_artist_page_artist_cover(self):
        return self.wait_select_single("*",
                                       objectName="artistpage-albumcover")

    def get_artiststab(self):
        return self.select_single("Tab", objectName="artiststab")

    def get_artists_artist_list(self):
        return self.select_many("Label", objectName="artists-artist")

    def get_artists_artist(self, artistName):
        artistList = self.get_artists_artist_list()
        for item in artistList:
            if item.text == artistName:
                return item

    def get_playlistslist(self):  # TODO: put in PlaylistPage helper
        return self.wait_select_single(
            "QQuickListView", objectName="playlistslist")
