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

require 'optparse'

module Amazing

  # Parse and manage command line options
  class Options < Hash
    def initialize(args=ARGV)
      @args = args
      initialize_defaults
      initialize_parser
    end

    def parse(args=@args)
      @parser.parse!(args)
    end

    def help
      @parser.help
    end

    private

    def initialize_defaults
      self[:config] = Dir["#{ENV["HOME"]}/.amazing/config.{rb,yml,yaml}"][0]
      self[:loglevel] = "info"
      self[:include] = []
      self[:autoinclude] = true
      self[:update] = []
    end

    def initialize_parser
      @parser = OptionParser.new do |opts|
        opts.on("-c", "--config FILE", "Configuration file (~/.amazing/config.{rb,yml,yaml})") do |config|
          self[:config] = config
        end

        opts.on("-g", "--scaffold [AWESOMERC]", "Generate a scaffold config") do |awesomerc|
          self[:scaffold] = awesomerc || File.expand_path("~/.awesomerc")
        end

        opts.on("-l", "--log-level LEVEL", "Severity threshold (info)") do |level|
          self[:loglevel] = level
        end

        opts.on("-s", "--stop", "Stop the running amazing process") do
          self[:stop] = true
        end

        opts.on("-i", "--include SCRIPT", "Include a widgets script") do |script|
          self[:include] << script
        end

        opts.on("--no-auto-include", "Don't auto include from ~/.amazing/widgets/") do
          self[:autoinclude] = false
        end

        opts.on("-u", "--update [WIDGET]", "Update a widget and exit") do |widget|
          if widget
            self[:update] << widget
          else
            self[:update] = :all
          end
        end

        opts.on("-w", "--list-widgets [WIDGET]", "List available widgets or options and fields for a widget") do |widget|
          self[:listwidgets] = widget || true
        end

        opts.on("-t", "--test-widget WIDGET [OPTIONS]", "Dump field values for a widget configured with inline YAML") do |widget|
          self[:test] = widget
        end

        opts.on("-h", "--help", "You're looking at it") do
          self[:help] = true
        end
      end
    end
  end
end
