# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'
require 'amazing/proc_file'

module Amazing
  module Widgets
    class AcAdapter < Widget
      description "AC adapter status"
      field :online, "Online status"
      default { @online ? "online" : "offline" }

      init do
        state = ProcFile.parse_file(Dir["/proc/acpi/ac_adapter/*/state"][0])[0]["state"]
        @online = {"on-line" => true, "off-line" => false}[state]
      end
    end
  end
end
