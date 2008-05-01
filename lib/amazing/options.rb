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
  class Options
    include Enumerable

    def initialize(args)
      @options = {}
      @options[:config] = "#{ENV["HOME"]}/.amazing/config.yml"
      @options[:loglevel] = "info"
      @options[:include] = []
      @options[:autoinclude] = true
      @options[:update] = []
      @args = args
      @parser = OptionParser.new do |opts|
        opts.on("-c", "--config FILE", "Configuration file (~/.amazing/config.yml)") do |config|
          @options[:config] = config
        end
        opts.on("-l", "--log-level LEVEL", "Severity threshold (info)") do |level|
          @options[:loglevel] = level
        end
        opts.on("-s", "--stop", "Stop the running amazing process") do
          @options[:stop] = true
        end
        opts.on("-i", "--include SCRIPT", "Include a widgets script") do |script|
          @options[:include] << script
        end
        opts.on("--no-auto-include", "Don't auto include from ~/.amazing/widgets/") do
          @options[:autoinclude] = false
        end
        opts.on("-u", "--update [WIDGET]", "Update a widget and exit") do |widget|
          if widget
            @options[:update] << widget
          else
            @options[:update] = :all
          end
        end
        opts.on("-w", "--list-widgets [WIDGET]", "List available widgets or options and fields for a widget") do |widget|
          @options[:listwidgets] = widget || true
        end
        opts.on("-t", "--test-widget WIDGET [OPTIONS]", "Dump field values for a widget configured with inline YAML") do |widget|
          @options[:test] = widget
        end
        opts.on("-h", "--help", "You're looking at it") do
          @options[:help] = true
        end
      end
    end

    def each
      @options.keys.each do |key|
        yield key
      end
    end

    def parse(args=@args)
      @parser.parse!(args)
    end

    def help
      @parser.help
    end

    def [](option)
      @options[option]
    end

    def []=(option, value)
      @options[option] = value
    end
  end
end
