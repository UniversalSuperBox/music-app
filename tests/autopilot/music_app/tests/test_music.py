# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

from __future__ import absolute_import

import time
import logging
from autopilot.matchers import Eventually
from testtools.matchers import Equals, LessThan, NotEquals


from music_app.tests import MusicAppTestCase

logger = logging.getLogger(__name__)


class TestMainWindow(MusicAppTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()

        self.album_artist_index = 0  # position on AlbumsPage
        self.album_index = 0  # position on MusicAlbums
        self.artist_index = 0  # position on MusicArtists
        self.track_index = 0  # position on MusicTracks
        self.track_title = u"Gran Vals"
        self.artist_name = u"Francisco Tárrega"
        self.last_track_title = u"TestMP3Title"

    @property
    def main_view(self):
        return self.app.main_view

    @property
    def player(self):
        return self.app.player

    @property
    def pointing_device(self):
        return self.app.app.pointing_device

    def test_reads_music_library(self):
        """ tests if the music library is populated from our
        fake mediascanner database"""

        self.app.populate_queue()  # populate queue

        title = lambda: self.player.currentMetaTitle
        artist = lambda: self.player.currentMetaArtist
        self.assertThat(title, Eventually(Equals(self.track_title)))
        self.assertThat(artist, Eventually(Equals(self.artist_name)))

    def test_play_pause_library(self):
        """ Test playing and pausing a track (Music Library must exist) """

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        # switch to albums tab
        albums_page = self.app.get_albums_page()
        albums_page.click_album(self.album_index)  # select album

        # get track item to swipe and queue
        songs_page = self.app.get_songs_page()

        track = songs_page.get_track(0)
        track.swipe_reveal_actions()

        track.click_add_to_queue_action()  # add track to the queue

        # verify track queue has added one to initial value
        self.assertThat(now_playing_page.get_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        end_tracks_count = now_playing_page.get_count()

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(end_tracks_count)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(self.artist_name))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(self.track_title))

        # click on close button to close the page
        self.main_view.go_back()

        """ Track is playing"""
        if self.main_view.wideAspect:
            click_play_button = toolbar.click_play_button
        else:
            if not toolbar.opened:
                toolbar.show()

            click_play_button = toolbar.click_small_play_button

        click_play_button()

        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Track is not playing"""
        click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

    def test_play_pause_now_playing(self):
        """ Test playing and pausing a track (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        toolbar = self.app.get_toolbar()

        """ Track is playing"""
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        toolbar.click_play_button()

        """ Track is not playing"""
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        """ Track is playing"""
        toolbar.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_next_previous(self):
        """ Test going to next track (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        toolbar = self.app.get_toolbar()

        title = lambda: self.player.currentMetaTitle
        artist = lambda: self.player.currentMetaArtist

        orgTitle = self.player.currentMetaTitle
        orgArtist = self.player.currentMetaArtist

        # check original track
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        logger.debug("Original Song %s, %s" % (orgTitle, orgArtist))

        """ Pause track """
        toolbar.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        toolbar.set_shuffle(False)

        """ Select next """
        # goal is to go back and forth and ensure 2 different songs
        toolbar.click_forward_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Pause track """
        toolbar.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # ensure different song
        self.assertThat(title, Eventually(NotEquals(orgTitle)))
        self.assertThat(artist, Eventually(NotEquals(orgArtist)))
        nextTitle = self.player.currentMetaTitle
        nextArtist = self.player.currentMetaArtist
        logger.debug("Next Song %s, %s" % (nextTitle, nextArtist))

        toolbar.seek_to(0)  # seek to 0 (start)

        """ Select previous """
        toolbar.click_previous_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Pause track """
        toolbar.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # ensure we're back to original song
        self.assertThat(title, Eventually(Equals(orgTitle)))
        self.assertThat(artist, Eventually(Equals(orgArtist)))

    def test_mp3(self):
        """ Test that mp3 "plays" or at least doesn't crash on load """

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        title = self.player.currentMetaTitle
        artist = self.player.currentMetaArtist

        toolbar.set_shuffle(False)

        # ensure track appears before looping through queue more than once
        # needs to contain test mp3 metadata and end in *.mp3
        queue_size = now_playing_page.get_count()
        count = 0

        while title != "TestMP3Title" and artist != "TestMP3Artist":
            count = count + 1

            self.assertThat(count, LessThan(queue_size))

            """ Select next """
            toolbar.click_forward_button()

            """ Pause track """
            toolbar.click_play_button()
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(False)))

            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist
            logger.debug("Current Song %s, %s" % (title, artist))
            logger.debug("File found %s" % self.player.currentMetaFile)

        # make sure mp3 plays
        self.assertThat(self.player.source.endswith("mp3"),
                        Equals(True))
        toolbar.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_shuffle(self):
        """ Test shuffle (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        """ Track is playing, shuffle is turned on"""
        toolbar = self.app.get_toolbar()

        # play for a second, then pause
        if not self.player.isPlaying:
            logger.debug("Play not selected")
            toolbar.click_play_button()
        else:
            logger.debug("Already playing")

        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        time.sleep(1)
        toolbar.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        count = 0
        while True:
            self.assertThat(count, LessThan(100))

            # goal is to hit next under shuffle mode
            # then verify original track is not the previous track
            # this means a true shuffle happened
            # if it doesn't try again, up to count times

            orgTitle = self.player.currentMetaTitle
            orgArtist = self.player.currentMetaArtist
            logger.debug("Original Song %s, %s" % (orgTitle, orgArtist))

            if not toolbar.opened:
                toolbar.show()

            toolbar.set_shuffle(True)

            toolbar.click_forward_button()
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(True)))

            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist
            logger.debug("Current Song %s, %s" % (title, artist))

            # go back to previous and check against original
            # play song, then pause before switching
            time.sleep(1)
            toolbar.click_play_button()
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(False)))

            toolbar.set_shuffle(False)

            toolbar.click_previous_button()

            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist

            if title != orgTitle and artist != orgArtist:
                # we shuffled properly
                logger.debug("Yay, shuffled %s, %s" % (title, artist))
                break
            else:
                logger.debug("Same track, no shuffle %s, %s" % (title, artist))

            count += 1

    def test_show_albums_page(self):
        """tests navigating to the Albums tab and displaying the album page"""

        # switch to albums tab
        albums_page = self.app.get_albums_page()
        albums_page.click_album(self.album_index)  # select album

        # get songs page album artist
        songs_page = self.app.get_songs_page()
        artist_label = songs_page.get_header_artist_label()

        self.assertThat(artist_label.text,
                        Eventually(Equals(self.artist_name)))

        # click on close button to close songs page
        self.main_view.go_back()

        # check that the albums page is now visible
        self.assertThat(albums_page.visible, Eventually(Equals(True)))

    def test_add_song_to_queue_from_albums_page(self):
        """tests navigating to the Albums tab and adding a song to queue"""

        now_playing_page = self.app.get_now_playing_page()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        # switch to albums tab
        albums_page = self.app.get_albums_page()
        albums_page.click_album(self.album_index)  # select album

        # get track item to swipe and queue
        songs_page = self.app.get_songs_page()

        track = songs_page.get_track(0)
        track.swipe_reveal_actions()

        track.click_add_to_queue_action()  # add track to the queue

        # verify track queue has added one to initial value
        self.assertThat(now_playing_page.get_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(self.artist_name))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(self.track_title))

        # click on close button to close songs page
        self.main_view.go_back()

        # check that the albums page is now visible
        self.assertThat(albums_page.visible, Eventually(Equals(True)))

    def test_add_songs_to_queue_from_songs_tab_and_play(self):
        """tests navigating to the Songs tab and adding the library to the
           queue with the selected item being played. """

        now_playing_page = self.app.get_now_playing_page()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        self.app.populate_queue()  # populate queue

        # get now playing again as it has moved
        now_playing_page = self.app.get_now_playing_page()

        # verify track queue has added all songs to initial value
        self.assertThat(now_playing_page.get_count(),
                        Equals(initial_tracks_count + 3))

        # Assert that the song added to the list is playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(now_playing_page.get_count())))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(self.artist_name))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(self.track_title))

    def test_add_song_to_queue_from_songs_tab(self):
        """tests navigating to the Songs tab and adding a song from the library
           to the queue via the expandable list view item. """

        now_playing_page = self.app.get_now_playing_page()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        # switch to tracks page
        tracks_page = self.app.get_tracks_page()

        # get track row and swipe to reveal actions
        track = tracks_page.get_track(self.track_index)
        track.swipe_reveal_actions()

        track.click_add_to_queue_action()  # add track to queue

        # verify track queue has added all songs to initial value
        self.assertThat(now_playing_page.get_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(now_playing_page.get_count())))
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(self.artist_name))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(self.track_title))

    def test_create_playlist_from_songs_tab(self):
        """tests navigating to the Songs tab and creating a playlist by
           selecting a song to add it to a new playlist. """

        # switch to tracks page
        tracks_page = self.app.get_tracks_page()

        # get track row and swipe to reveal actions
        track = tracks_page.get_track(self.track_index)
        track.swipe_reveal_actions()

        track.click_add_to_playlist_action()  # add track to queue

        add_to_playlist_page = self.app.get_add_to_playlist_page()

        # get initial list view playlist count
        playlist_count = add_to_playlist_page.get_count()

        # click on New playlist button in header
        add_to_playlist_page.click_new_playlist_action()

        # get dialog
        new_dialog = self.app.get_new_playlist_dialog()

        # input playlist name
        new_dialog.type_new_playlist_dialog_name("myPlaylist")

        # click on the create Button
        new_dialog.click_new_playlist_dialog_create_button()

        # verify playlist has been sucessfully created
        self.assertThat(add_to_playlist_page.get_count(),
                        Eventually(Equals(playlist_count + 1)))

        self.assertThat(add_to_playlist_page.get_playlist(0).name,
                        Equals("myPlaylist"))

        # select playlist to add song to
        add_to_playlist_page.click_playlist(0)

        # wait for add to playlist page to close
        add_to_playlist_page.visible.wait_for(False)

        # open playlists page
        playlists_page = self.app.get_playlists_page()

        # verify song has been added to playlist
        self.assertThat(playlists_page.get_count(), Equals(1))

    def test_artists_tab_album(self):
        """tests navigating to the Artists tab and playing an album"""

        now_playing_page = self.app.get_now_playing_page()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        # switch to artists tab
        artists_page = self.app.get_artists_page()
        artists_page.click_artist(self.artist_index)

        # get albums (by an artist) page
        albums_page = self.app.get_albums_artist_page()

        # check album artist label is correct
        self.assertThat(albums_page.get_artist(), Equals(self.artist_name))

        # click on album to show tracks
        albums_page.click_artist(self.album_artist_index)

        # get song page album artist
        songs_page = self.app.get_songs_page()

        # check the artist label
        artist_label = songs_page.get_header_artist_label()
        self.assertThat(artist_label.text, Equals(self.artist_name))

        # click on track to play
        songs_page.click_track(self.track_index)

        # get now playing again as it has moved
        now_playing_page = self.app.get_now_playing_page()

        # verify track queue has added all songs to initial value
        self.assertThat(now_playing_page.get_count(),
                        Equals(initial_tracks_count + 2))

        # Assert that the song added to the list is playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(now_playing_page.get_count())))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(self.artist_name))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(self.track_title))

    def test_swipe_to_delete_song(self):
        """tests navigating to the Now Playing queue, swiping to delete a
        track, and confirming the delete action. """

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        # get initial queue count
        initial_queue_count = now_playing_page.get_count()

        # get track row and swipe to reveal swipe to delete
        track = now_playing_page.get_track(self.track_index)
        track.swipe_to_delete()

        track.confirm_removal()  # confirm delete

        # verify song has been deleted
        self.assertThat(now_playing_page.get_count(),
                        Eventually(Equals(initial_queue_count - 1)))

    def test_playback_stops_when_last_song_ends_and_repeat_off(self):
        """Check that playback stops when the last song in the queue ends"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        toolbar.set_shuffle(False)
        toolbar.set_repeat(False)

        # Skip through all songs in queue, stopping on last one.
        for count in range(0, now_playing_page.get_count() - 1):
            toolbar.click_forward_button()

        # When the last song ends, playback should stop
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

    def test_playback_repeats_when_last_song_ends_and_repeat_on(self):
        """With repeat on, the 1st song should play after the last one ends"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        toolbar.set_shuffle(False)
        toolbar.set_repeat(True)

        # Skip through all songs in queue, stopping on last one.
        for count in range(0, now_playing_page.get_count() - 1):
            toolbar.click_forward_button()

        # Make sure we loop back to first song after last song ends
        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title, Eventually(Equals(self.track_title)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_next_from_last_song_plays_first_when_repeat_on(self):
        """With repeat on, skipping the last song jumps to the first track"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        toolbar.set_shuffle(False)
        toolbar.set_repeat(True)

        # Skip through all songs in queue, INCLUDING last one.
        for count in range(0, now_playing_page.get_count() - 1):
            toolbar.click_forward_button()

        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title, Eventually(Equals(self.track_title)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_prev_from_first_song_plays_last_when_repeat_on(self):
        """With repeat on, 'previous' from the 1st song plays the last one."""

        self.app.populate_queue()  # populate queue

        toolbar = self.app.get_toolbar()

        toolbar.set_shuffle(False)
        toolbar.set_repeat(True)

        initial_song = self.player.currentMetaTitle
        toolbar.click_previous_button()

        # If we're far enough into a song, pressing prev just takes us to the
        # beginning of that track.  In that case, hit prev again to actually
        # skip over the track.
        if self.player.currentMetaTitle == initial_song:
            toolbar.click_previous_button()

        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title,
                        Eventually(Equals(self.last_track_title)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
