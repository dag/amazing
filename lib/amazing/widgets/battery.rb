# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'
require 'amazing/proc_file'

module Amazing
  module Widgets
    class Battery < Widget
      description "Remaining battery power in percentage"
      option :battery, "Battery number", 1
      field :percentage, "Power percentage"
      default { @percentage.to_i }

      init do
        batinfo = ProcFile.parse_file("acpi/battery/BAT#@battery/info")[0]
        batstate = ProcFile.parse_file("acpi/battery/BAT#@battery/state")[0]
        remaining = batstate["remaining capacity"].to_i
        lastfull = batinfo["last full capacity"].to_i
        @percentage = (remaining * 100) / lastfull.to_f
      end
    end
  end
end
