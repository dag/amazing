# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

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
