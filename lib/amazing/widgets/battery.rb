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
require 'amazing/proc_file'

module Amazing
  module Widgets
    class Battery < Widget
      description "Remaining battery power in percentage"
      option :battery, "Battery number", 1
      field :state, "Charging state, :charged, :charging or :discharging"
      field :percentage, "Power percentage"
      default { @percentage.to_i }

      init do
        batinfo = ProcFile.parse_file("acpi/battery/BAT#@battery/info")[0]
        batstate = ProcFile.parse_file("acpi/battery/BAT#@battery/state")[0]
        remaining = batstate["remaining capacity"].to_i
        lastfull = batinfo["last full capacity"].to_i
        @state = batstate["charging state"].to_sym
        @percentage = (remaining * 100) / lastfull.to_f
      end
    end

    private

    def charged?
      @state == :charged
    end

    def charging?
      @state == :charging
    end

    def discharging?
      @state == :discharging
    end
  end
end
