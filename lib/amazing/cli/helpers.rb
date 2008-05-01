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
    module Helpers
      private

      def parse_options
        @options.parse
      end

      def set_loglevel
        begin
          @log.level = Logger.const_get(@options[:loglevel].upcase)

        rescue NameError
          @log.error("Unsupported log level #{@options[:loglevel].inspect}")
          @log.level = Logger::INFO
        end
      end

      def stop_process(log=true)
        Process.kill("SIGINT", File.read("#{ENV["HOME"]}/.amazing/pids/#{@display.display}.pid").to_i) 
        @log.warn("Killed older process") if log
      rescue
      end

      def load_scripts
        scripts = @options[:include]

        if @options[:autoinclude]
          scripts << Dir["#{ENV["HOME"]}/.amazing/widgets/*"]
        end

        scripts.flatten.each do |script|
          if File.exist?(script)
            @log.debug("Loading script #{script.inspect}")

            begin
              Widgets.module_eval(File.read(script), script)

            rescue SyntaxError => e
              @log.error("Bad syntax in #{script} at line #{e.to_s.scan(/:(\d+)/)}")
            end

          else
            @log.error("No such widget script #{script.inspect}")
          end
        end
      end

      def parse_config
        @log.debug("Parsing configuration file")

        begin
          @config = Config.new(@options[:config])

        rescue
          @log.fatal("Unable to parse configuration file, exiting")

          exit 1
        end
      end

      def wait_for_sockets
        @log.debug("Waiting for awesome control socket for display #{@display.display}")

        begin
          Timeout.timeout(30) do
            sleep 1 until File.exist?("#{ENV["HOME"]}/.awesome_ctl.#{@display.display}")
            @log.debug("Got socket for display #{@display.display}")
          end

        rescue Timeout::Error
          @log.fatal("Socket for display #{@display.display} not created within 30 seconds, exiting")

          exit 1
        end
      end

      def save_pid
        path = "#{ENV["HOME"]}/.amazing/pids"
        FileUtils.makedirs(path)

        File.open("#{path}/#{@display.display}.pid", "w+") do |f|
          f.write($$)
        end
      end

      def remove_pid
        File.delete("#{ENV["HOME"]}/.amazing/pids/#{@display.display}.pid") rescue Errno::ENOENT
      end

      def set_traps
        trap("SIGINT") do
          @log.fatal("Received SIGINT, exiting")
          remove_pid
          exit
        end
      end

      def update_non_interval
        @threads << Thread.new do
          @config[:awesome].each do |awesome|
            awesome[:widgets].each do |widget|
              next if widget[:interval]

              @threads << Thread.new(awesome, widget) do |awesome, widget|
                update_widget(awesome[:screen], awesome[:statusbar], widget)
              end
            end
          end
        end
      end

      def update_widget(screen, statusbar, widget, iteration=0)
        threads = []
        @log.debug("Updating widget #{widget[:identifier]} of type #{widget[:module]} on screen #{screen}")

        begin
          mod = Widgets.const_get(widget[:module]).new(widget.merge(:iteration => iteration))

          if widget[:properties].empty?
            threads << Thread.new(screen, statusbar, widget, mod) do |screen, statusbar, widget, mod|
              @awesome.widget_tell(screen, statusbar, widget[:identifier], widget[:property], mod.formatize)
            end
          end

          widget[:properties].each do |property, format|
            threads << Thread.new(screen, statusbar, widget, property, mod, format) do |screen, statusbar, widget, property, mod, format|
              @awesome.widget_tell(screen, statusbar, widget[:identifier], property, mod.formatize(format))
            end
          end

        rescue WidgetError => e
          @log.error(widget[:module]) { e.message }
        end

        threads.each {|t| t.join }
      end

      def join_threads
        @threads.each {|t| t.join }
      end
    end
  end
end
