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

module Amazing
  module Widgets
    class FileSystem < Widget
      description "Various filesystem information"
      option :mountpoint, "Mountpoint for default format", "/"
      field :size, "Total size of volume in MB", {}
      field :used, "Size of used data in MB", {}
      field :free, "Size of free data in MB", {}
      field :percentage, "Percentage of used space", {}
      field :device, "Device name of mount point", {}
      default { @percentage[@mountpoint] }

      init do
        IO.popen("df") do |io|
          io.readlines[1..-1].map {|l| l.split }.each do |fs|
            @device[fs[5]] = fs[0].to_s
            @size[fs[5]] = fs[1].to_f / 1024
            @used[fs[5]] = fs[2].to_f / 1024
            @free[fs[5]] = fs[3].to_f / 1024
            @percentage[fs[5]] = fs[4].to_i
          end
        end
      end
    end
  end
end
