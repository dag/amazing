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
