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

module Amazing

  # Parse a /proc file
  #
  #   cpuinfo = ProcFile.parse_file("cpuinfo")
  #   cpuinfo[1]["model name"]
  #   #=> "AMD Turion(tm) 64 X2 Mobile Technology TL-50"
  class ProcFile
    include Enumerable

    def self.parse_file(file)
      file = File.expand_path(file, "/proc")
      new(File.new(file))
    end

    def initialize(string_or_io)
      case string_or_io
      when String
        content = string_or_io
      when IO
        content = string_or_io.read
        string_or_io.close
      end
      @list = [{}]
      content.each_line do |line|
        if sep = line.index(":")
          @list[-1][line[0..sep-1].strip] = line[sep+1..-1].strip
        else
          @list << {}
        end
      end
      @list.pop if @list[-1].empty?
    end

    def each
      @list.each do |section|
        yield section
      end
    end

    def [](section)
      @list[section]
    end
  end
end
