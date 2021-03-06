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
    class Clock < Widget
      description "Displays date and time"
      option :format, "Time format as described in DATE(1)", "%R"
      option :offset, "UTC offset in hours", Time.now.utc_offset / 3600
      field :time, "Formatted time"
      default { @time }

      init do
        @time = (Time.now.utc + @offset.to_f * 3600).strftime(@format)
      end
    end
  end
end
