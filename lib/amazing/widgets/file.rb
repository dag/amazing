# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
    class File < Widget
      description "Information for a file"
      option :file, "The file to work with", ""
      field :lines, "All the lines in the file", []
      field :first, "The first line in the file", ""
      field :last, "The last line in the file", ""
      field :count, "Number of lines in the file", 0
      field :time_format, "Time format for timestamps as described in DATE(1)", "%c"
      field :atime, "Access time", Time.now.strftime("%c")
      field :ctime, "Change time", Time.now.strftime("%c")
      field :mtime, "Modification time", Time.now.strftime("%c")
      default "@last"

      init do
        @file = "#{ENV["HOME"]}/#@file" if @file[0] != ?/
        @lines = ::File.readlines(@file).map {|line| line.chomp }
        @first = @lines.first || ""
        @last = @lines.last || ""
        @count = @lines.size
        @atime = ::File.atime(@file).strftime(@time_format)
        @ctime = ::File.ctime(@file).strftime(@time_format)
        @mtime = ::File.mtime(@file).strftime(@time_format)
      end
    end
  end
end
