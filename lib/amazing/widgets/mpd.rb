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
    class Mpd < Widget
      description "MPD Information"
      dependency "socket", "Ruby standard library"
      option :hostname, "MPD server hostname", "localhost"
      option :port, "MPD server port number", 6600
      option :password, "Authentication password"
      field :state, "Play state, :playing, :paused or :stopped"
      field :artist, "Song artist"
      field :title, "Song title"
      field :length, "Song length"
      field :position, "Song position"
      field :date, "Song date from ID3 tag"
      field :id, "Song ID in playlist"
      field :genre, "Song genre"
      field :album, "Song album"
      field :file, "Filename of current song"
      field :shortfile, "Filename without directory path and extension"
      field :percentage, "Finished percentage of current song", 0.0
      field :random, "True if playlist is on random"
      field :repeat, "True if playlist is on repeat"
      field :volume, "Volume of MPD mixer", 0

      default do
        track = "#{@artist && "#@artist - "}#@title"
        track = @shortfile if track.empty?
        case @state
        when :playing
          track
        when :paused
          "#{track} [paused]"
        when :stopped
          "[mpd not playing]"
        end
      end

      init do
        mpd = get_socket
        status = send_command(:status)
        @state = {:play => :playing, :pause => :paused, :stop => :stopped}[status["state"].to_sym]
        @random = {0 => false, 1 => true}[status["random"].to_i]
        @repeat = {0 => false, 1 => true}[status["repeat"].to_i]
        @volume = status["volume"].to_i
        if song = send_command(:currentsong)
          @artist = song["Artist"]
          @title = song["Title"]
          len = song["Time"].to_i
          minutes = (len / 60) % 60
          seconds = len % 60
          @length = "%d:%02d" % [minutes, seconds]
          pos = status["time"].to_i
          minutes = (pos / 60) % 60
          seconds = pos % 60
          @position = "%d:%02d" % [minutes, seconds]
          @date = song["Date"]
          @id = song["Id"].to_i
          @genre = song["Genre"]
          @album = song["Album"]
          @file = song["file"]
          @shortfile = ::File.basename(@file)
          @shortfile = @shortfile[0..-::File.extname(@shortfile).length-1]
          @percentage = pos == 0 ? 0.0 : pos / len.to_f * 100
        end
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

      def get_socket
        @@connections ||= {}
        mpd = nil
        unless @@connections["#@identifier"]
          @@connections["#@identifier"] = TCPSocket.new(@hostname, @port)
          mpd = @@connections["#@identifier"]
          mpd.gets
          authenticate
        else
          mpd = @@connections["#@identifier"]
          mpd.puts("ping")
          unless mpd.gets
            @@connections["#@identifier"] = TCPSocket.new(@hostname, @port)
            mpd = @@connections["#@identifier"]
            mpd.gets
            authenticate
          end
        end
        mpd
      end

      def authenticate
        mpd = @@connections["#@identifier"]
        if @password
          mpd.puts("password #@password")
          if mpd.gets.split[0] == "ACK"
            raise WidgetError, "incorrect password"
          end
        end
      end

      def send_command(command)
        mpd = @@connections["#@identifier"]
        mpd.puts(command.to_s)
        lines = []
        loop do
          line = mpd.gets
          if line.split[0] == "ACK"
            raise WidgetError, line.scan(/\{#{command}\} (.+)/).to_s
          elsif line.split[0] == "OK"
            return ProcFile.new(lines.join)[0]
          else
            lines << line
          end
        end
      end
    end
  end
end
