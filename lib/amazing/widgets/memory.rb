# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'
require 'amazing/proc_file'

module Amazing
  module Widgets
    class Memory < Widget
      description "Various memory related data"
      field :total, "Total kilobytes of memory", 0
      field :free, "Free kilobytes of memory", 0
      field :buffers, "Buffered kilobytes of memory", 0
      field :cached, "Cached kilobytes of memory", 0
      field :usage, "Percentage of used memory", 0.0
      default "@usage"

      init do
        meminfo = ProcFile.parse_file("meminfo")[0]
        @total = meminfo["MemTotal"].to_i
        @free = meminfo["MemFree"].to_i
        @buffers = meminfo["Buffers"].to_i
        @cached = meminfo["Cached"].to_i
        @usage = ((@total - @free - @cached - @buffers) * 100) / @total.to_f
      end
    end
  end
end
