# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing'
require 'amazing/cli/commands'
require 'amazing/cli/helpers'
require 'amazing/cli/initializers'
require 'fileutils'
require 'logger'
require 'thread'
require 'timeout'
require 'yaml'

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
