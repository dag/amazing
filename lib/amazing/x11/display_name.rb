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

module Amazing
  module X11

    # Raised by DisplayName#new if called with empty argument, or without
    # argument and ENV["DISPLAY"] is empty.
    class EmptyDisplayName < ArgumentError
    end

    # Raised by DisplayName#new if format of argument or ENV["DISPLAY"] is
    # invalid.
    class InvalidDisplayName < ArgumentError
    end

    # Parse an X11 display name
    #
    #   display = DisplayName.new("hostname:displaynumber.screennumber")
    #   display.hostname #=> "hostname"
    #   display.display  #=> "displaynumber"
    #   display.screen   #=> "screennumber"
    #
    # Without arguments, reads ENV["DISPLAY"]. With empty argument or
    # DISPLAY environment, raises EmptyDisplayName. With invalid display name
    # format, raises InvalidDisplayName. 
    class DisplayName
      attr_reader :hostname, :display, :screen

      def initialize(display_name=ENV["DISPLAY"])
        raise EmptyDisplayName, "No display name supplied" if ["", nil].include? display_name
        @hostname, @display, @screen = display_name.scan(/^(.*):(\d+)(?:\.(\d+))?$/)[0]
        raise InvalidDisplayName, "Invalid display name" if @display.nil?
        @hostname = "localhost" if @hostname.empty?
        @screen = "0" unless @screen
      end
    end
  end
end
