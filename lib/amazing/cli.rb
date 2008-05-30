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

require 'amazing'
require 'amazing/cli/commands'
require 'amazing/cli/helpers'
require 'amazing/cli/initializers'
require 'fileutils'
require 'logger'
require 'thread'
require 'timeout'

module Amazing

  # Command line interface runner
  #
  #   CLI.new(ARGV).run
  class CLI
    include Initializers
    include Helpers
    include Commands

    def initialize(args=ARGV)
      @args = args
      initialize_threads
      initialize_encoding
      initialize_logger
      initialize_options
      initialize_display
      initialize_awesome
      initialize_exit
    end

    def run
      parse_options
      cmd_show_help
      cmd_scaffold
      set_loglevel
      cmd_stop_process
      load_scripts
      cmd_list_widgets
      cmd_test_widget
      parse_config
      wait_for_sockets
      cmd_explicit_updates
      stop_process
      save_pid
      set_traps
      update_non_interval
      cmd_main
      join_threads
    end
  end
end
