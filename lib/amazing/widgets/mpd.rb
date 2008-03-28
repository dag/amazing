# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'
require 'amazing/proc_file'

module Amazing
  module Widgets
    class MPD < Widget
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
          @percentage = pos / len.to_f * 100
        end
      end

      private

      def get_socket
        @@connections ||= {}
        mpd = nil
        unless @@connections["#@hostname:#@port"]
          @@connections["#@hostname:#@port"] = TCPSocket.new(@hostname, @port)
          mpd = @@connections["#@hostname:#@port"]
          mpd.gets
          authenticate
        else
          mpd = @@connections["#@hostname:#@port"]
          mpd.puts("ping")
          unless mpd.gets
            @@connections["#@hostname:#@port"] = TCPSocket.new(@hostname, @port)
            mpd = @@connections["#@hostname:#@port"]
            mpd.gets
            authenticate
          end
        end
        mpd
      end

      def authenticate
        mpd = @@connections["#@hostname:#@port"]
        if @password
          mpd.puts("password #@password")
          if mpd.gets.split[0] == "ACK"
            raise WidgetError, "incorrect password"
          end
        end
      end

      def send_command(command)
        mpd = @@connections["#@hostname:#@port"]
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
