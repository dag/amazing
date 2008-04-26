# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

module Amazing
  class CLI
    module Initializers
      private

      def initialize_threads
        @threads = []
      end

      def initialize_encoding
        $KCODE = "utf-8"
      end

      def initialize_logger
        @log = Logger.new(STDOUT)
      end

      def initialize_options
        @options = Options.new(@args)
      end

      def initialize_display
        begin
          @display = X11::DisplayName.new

        rescue X11::EmptyDisplayName => e
          @log.warn("#{e.message}, falling back on :0")
          @display = X11::DisplayName.new(":0")

        rescue X11::InvalidDisplayName => e
          @log.fatal("#{e.message}, exiting")

          exit 1
        end
      end

      def initialize_awesome
        @awesome = Awesome.new(@display.display)
      end

      def initialize_exit
        at_exit { Thread.list.each {|t| t.exit } }
      end
    end
  end
end
