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
    class Pacman < Widget
      description "Available upgrades in the Pacman package manager"
      option :pacman, "Path to the pacman program", "pacman"
      field :packages, "List of available upgrades", []
      field :count, "New package count", 0
      default { @count }

      init do
        IO.popen("#@pacman --query --upgrades") do |io|
          @packages = io.read.scan(/Targets: (.+)\n\n/m).to_s.split
          @count = @packages.size
        end
      end
    end
  end
end
