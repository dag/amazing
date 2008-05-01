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
    class Alsa < Widget
      description "Various data for the ALSA mixer"
      option :mixer, "ALSA mixer name", "Master"
      field :volume, "Volume in percentage", 0
      default { @volume }

      init do
        IO.popen("amixer get #@mixer", IO::RDONLY) do |am|
          out = am.read
          volumes = out.scan(/\[(\d+)%\]/).flatten
          volumes.each {|vol| @volume += vol.to_i }
          @volume = @volume / volumes.size
        end
      end
    end
  end
end
