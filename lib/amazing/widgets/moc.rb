# Copyright 2008 Dag Odenhall <dag.odenhall@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'amazing/widget'
require 'amazing/proc_file'

module Amazing
  module Widgets
    class Moc < Widget
      description "Music On Console status"
      option :mocp, "Path to mocp program", "mocp"
      field :state, "Play state, :playing, :paused or :stopped"
      field :file, "Playing file"
      field :title, "Title as seen by MOC"
      field :artist, "Artist name"
      field :song_title, "Song title"
      field :album, "Album of song"
      field :total_time, "Total length of song"
      field :time_left, "Time left of playing song"
      field :total_sec, "Total length of song in seconds"
      field :current_time, "Current position in playing song"
      field :current_sec, "Current position in playing song in seconds"
      field :bitrate, "Song bitrate"
      field :rate, "Song sample rate"

      default do
        case @state
        when :playing
          "#@artist - #@song_title"
        when :paused
          "#@artist - #@song_title [paused]"
        when :stopped
          "[moc not playing]"
        end
      end

      init do
        moc = ProcFile.new(IO.popen("#@mocp --info"))[0]
        @state = {:play => :playing, :pause => :paused, :stop => :stopped}[moc["State"].downcase.to_sym]
        @file = moc["File"]
        @title = moc["Title"]
        @artist = moc["Artist"]
        @song_title = moc["SongTitle"]
        @album = moc["Album"]
        @total_time = moc["TotalTime"]
        @time_left = moc["TimeLeft"]
        @total_sec = moc["TotalSec"].to_i
        @current_time = moc["CurrentTime"]
        @current_sec = moc["CurrentSec"].to_i
        @bitrate = moc["Bitrate"]
        @rate = moc["Rate"]
      end

      private

      def playing?
        @state == :playing
      end

      def paused?
        @state == :paused
      end

      def stopped?
        @state == :stopped
      end
    end
  end
end
