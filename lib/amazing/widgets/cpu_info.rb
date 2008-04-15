# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'
require 'amazing/proc_file'

module Amazing
  module Widgets

    # TODO: There might be more yummy stuff in /proc/cpuinfo
    class CpuInfo < Widget
      description "CPU Information"
      option :cpu, "CPU number for default format (0 based)", 0
      field :speed, "CPU Speed in MHz", []
      default { @speed[@cpu].to_i  }

      init do
        ProcFile.parse_file("cpuinfo").each_with_index do |info, cpu|
          @speed[cpu] = info["cpu MHz"].to_f
        end
      end
    end
  end
end
