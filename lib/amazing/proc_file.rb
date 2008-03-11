# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

module Amazing

  # Parse a /proc file
  #
  #   cpuinfo = ProcFile.parse_file("cpuinfo")
  #   cpuinfo[1]["model name"]
  #   #=> "AMD Turion(tm) 64 X2 Mobile Technology TL-50"
  class ProcFile
    include Enumerable

    def self.parse_file(file)
      file = "/proc/#{file}" if file[0] != ?/
      new(File.new(file))
    end

    def initialize(string_or_io)
      case string_or_io
      when String
        content = string_or_io
      when IO
        content = string_or_io.read
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
