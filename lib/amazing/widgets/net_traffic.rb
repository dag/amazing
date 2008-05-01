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
    class NetTraffic < Widget
      description "Network traffic information"
      option :interface, "Network interface", "eth0"
      option :upload_peak, "Maximum upstream of your Internet connection in kB/s", 56
      option :download_peak, "Maximum downstream of your Internet connection in kB/s", 56
      field :upload_rate, "Upload rate in kB/s"
      field :download_rate, "Download rate in kB/s"
      field :upload_total, "Amount of data uploaded in kB/s"
      field :download_total, "Amount of data downloaded in kB/s"
      field :upload_percentage, "Percentage upload"
      field :download_percentage, "Percentage download"
      default { @download_percentage.to_i }

      init do
        dev = ProcFile.parse_file("net/dev")[2][@interface].split
        first_down = dev[0].to_f
        first_up = dev[8].to_f
        sleep 1
        dev = ProcFile.parse_file("net/dev")[2][@interface].split
        second_down = dev[0].to_f
        second_up = dev[8].to_f
        @download_rate = (second_down - first_down) / 1024
        @download_total = second_down / 1024
        @upload_rate = (second_up - first_up) / 1024
        @upload_total = second_up / 1024
        @upload_percentage = @upload_rate * 100 / @upload_peak
        @download_percentage = @download_rate * 100 / @download_peak
      end
    end
  end
end
