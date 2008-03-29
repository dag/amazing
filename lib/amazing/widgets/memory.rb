# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'
require 'amazing/proc_file'

module Amazing
  module Widgets
    class Memory < Widget
      description "Various memory related data"
      field :total, "Total kilobytes of memory"
      field :free, "Free kilobytes of memory"
      field :buffers, "Buffered kilobytes of memory"
      field :cached, "Cached kilobytes of memory"
      field :usage, "Percentage of used memory"
      field :swap_total, "Total kilobytes of swap"
      field :swap_free, "Free kilobytes of swap"
      field :swap_cached, "Cached kilobytes of swap"
      field :swap_usage, "Percentage of used swap"
      default "@usage"

      init do
        meminfo = ProcFile.parse_file("meminfo")[0]
        @total = meminfo["MemTotal"].to_i
        @free = meminfo["MemFree"].to_i
        @buffers = meminfo["Buffers"].to_i
        @cached = meminfo["Cached"].to_i
        @usage = ((@total - @free - @cached - @buffers) * 100) / @total.to_f
        @swap_total = meminfo["SwapTotal"].to_i
        @swap_free = meminfo["SwapFree"].to_i
        @swap_cached = meminfo["SwapCached"].to_i
        @swap_usage = ((@swap_total - @swap_free - @swap_cached) * 100) / @swap_total.to_f
      end
    end
  end
end
