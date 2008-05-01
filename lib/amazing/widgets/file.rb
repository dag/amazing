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

module Amazing
  module Widgets
    class File < Widget
      description "Information for a file"
      option :file, "The file to work with", ""
      option :time_format, "Time format for timestamps as described in DATE(1)", "%c"
      field :lines, "All the lines in the file", []
      field :first, "The first line in the file", ""
      field :last, "The last line in the file", ""
      field :count, "Number of lines in the file", 0
      field :atime, "Access time", Time.now.strftime("%c")
      field :ctime, "Change time", Time.now.strftime("%c")
      field :mtime, "Modification time", Time.now.strftime("%c")
      default { @last }

      init do
        @file = ::File.expand_path(@file, "~")
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
