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
