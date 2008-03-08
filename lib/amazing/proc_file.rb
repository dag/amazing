# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

module Amazing

  # Parse a /proc file
  #
  #   cpuinfo = ProcFile.new("cpuinfo")
  #   cpuinfo[1]["model name"]
  #   #=> "AMD Turion(tm) 64 X2 Mobile Technology TL-50"
  class ProcFile
    include Enumerable

    def initialize(file)
      file = "/proc/#{file}" if file[0] != ?/
      @list = [{}]
      File.readlines(file).each do |line|
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
