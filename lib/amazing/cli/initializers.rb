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
