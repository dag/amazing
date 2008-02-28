#!/usr/bin/env ruby

#
# = amazing 
#
# an amazing widget manager for an awesome window manager
#
#   Usage: amazing [options]
#      -c, --config FILE                Configuration file (~/.amazing.yml)
#      -s, --screen ID                  Screen ID (0)
#      -l, --log-level LEVEL            Severity threshold (info)
#      -i, --include SCRIPT             Include a widgets script
#      -u, --update WIDGET              Update a widget and exit
#      -w, --list-widgets               List available widgets
#      -h, --help                       You're looking at it
#
# == Widgets
#
# * Battery: Remaining battery power in percentage
# * Maildir: Mail count in maildirs
# * ALSA: Various data for the ALSA mixer
# * Raggle: Unread posts in raggle
# * Memory: Various memory related data
# * Clock: Displays date and time
#
# == Configuration
#
#   include:
#     - list
#     - of
#     - scripts
#   screens:
#     - list
#     - of
#     - screens
#   widgets:
#     identifier:
#       type: WidgetName
#       every: seconds
#       field: instance method
#       options:
#         widget: foo
#         specific: bar
#
# == Example
# 
#   widgets:
#     pb_bat:
#       type: Battery
#       every: 10
#     tb_time:
#       type: Clock
#       every: 1
#       options:
#         format: %T
#     tb_mail:
#       type: Maildir
#       options:
#         directories:
#           - Mail/**/new
#           - Mail/inbox/cur
#
# In this example tb_mail doesn't have an "every" setting and is instead
# updated manually with <tt>amazing -u tb_mail</tt>, perhaps in cron after fetching
# new mail via fdm, getmail, fetchmail or similar. A good idea is also to
# update after closing your MUA such as Mutt which could be done with
# shell functions, example:
#
#   mutt() {
#     mutt $*
#     amazing -u tb_mail
#   }
#
# == Writing widgets
#
# Widgets inherit from Widget, serves data via instance methods, signalizes
# errors by raising a WidgetError and processes widget options via @options.
# The init method is used instead of initialize. Here's an example:
#
#   class MyWidget < Widget
#     description "This is my widget"
#     attr_reader :my_field
#     alias_method :default, :my_field
#
#     def init
#       @my_field = @options["text"] || "No text configured"
#       raise WidgetError, "oops!" if some_error?
#     end
#   end
#
# The ProcFile class can be used for parsing /proc files:
#
#   cpuinfo = ProcFile.new("cpuinfo")
#   cpuinfo[1]["model name"]
#   #=> "AMD Turion(tm) 64 X2 Mobile Technology TL-50"
#
# == Todo
#
# * Maybe auto-include scripts from ~/.amazing/something
# * Self-documenting widgets (list fields and options)
# * Some widgets need to support multiple data sources
# * Some way to do alerts, e.g. "blinking"
# * More widgets, duh
#
# == Copying
#
# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0
# http://www.rosenlaw.com/AFL3.0.htm
#

require 'optparse'
require 'logger'
require 'yaml'
require 'timeout'
require 'thread'
require 'pstore'

module Amazing

  # Communicate with awesome
  #
  #   awesome = Awesome.new
  #   awesome.widget_tell(widget_id, "Hello, world")
  #   awesome = Awesome.new(1)
  #   awesome.tag_view(3)
  #   Awesome.new.client_zoom
  class Awesome
    attr_accessor :screen

    def initialize(screen=0)
      @screen = screen.to_i
    end

    def method_missing(method, *args)
      IO.popen("awesome-client", IO::WRONLY) do |ac|
        ac.puts "#@screen #{method} #{args.join(' ')}"
      end
    end
  end

  # Parse a /proc file
  #
  #   cpuinfo = ProcFile.new("cpuinfo")
  #   cpuinfo[1]["model name"]
  #   #=> "AMD Turion(tm) 64 X2 Mobile Technology TL-50"
  class ProcFile
    include Enumerable

    def initialize(file)
      file = "/proc/#{file}" if file[0] != ?/
      @list = [{}]
      File.readlines(file).each do |line|
        if sep = line.index(":")
          @list[-1][line[0..sep-1].strip] = line[sep+1..-1].strip
        else
          @list << {}
        end
      end
      @list.pop if @list[-1].empty?
    end

    def each
      @list.each do |section|
        yield section
      end
    end

    def [](section)
      @list[section]
    end
  end

  # Raised by widgets, and is then rescued and logged
  class WidgetError < Exception
  end

  # Parent class for widget construction
  #
  #   class MyWidget < Widget
  #     description "This is my widget"
  #     attr_reader :my_field
  #     alias_method :default, :my_field
  #
  #     def init
  #       @my_field = @options["text"] || "No text configured"
  #       raise WidgetError, "oops!" if some_error?
  #     end
  #   end
  class Widget
    def initialize(opts={})
      @options = opts
      init if respond_to? :init
    end

    def self.description(description=nil)
      if description
        @description = description
      else
        @description
      end
    end
  end

  module Widgets
    class ALSA < Widget
      description "Various data for the ALSA mixer"
      attr_reader :volume
      alias_method :default, :volume

      def init
        mixer = @options["mixer"] || "Master"
        IO.popen("amixer get #{mixer}", IO::RDONLY) do |am|
          out = am.read
          volumes = out.scan(/\[(\d+)%\]/).flatten
          @volume = 0
          volumes.each {|vol| @volume += vol.to_i }
          @volume = @volume / volumes.size
        end
      end
    end

    class Battery < Widget
      description "Remaining battery power in percentage"
      attr_reader :percentage
      alias_method :default, :percentage

      def init
        battery = @options["battery"] || 1
        batinfo = ProcFile.new("acpi/battery/BAT#{battery}/info")[0]
        batstate = ProcFile.new("acpi/battery/BAT#{battery}/state")[0]
        remaining = batstate["remaining capacity"].to_i
        lastfull = batinfo["last full capacity"].to_i
        @percentage = (remaining * 100) / lastfull.to_f
      end
    end

    class Clock < Widget
      description "Displays date and time"
      attr_reader :time
      alias_method :default, :time

      def init
        format = @options["format"] || "%R"
        @time = Time.now.strftime(format)
      end
    end

    class Maildir < Widget
      description "Mail count in maildirs"
      attr_reader :count
      alias_method :default, :count

      def init
        @count = 0
        raise WidgetError, "No directories configured" unless @options["directories"]
        @options["directories"].each do |glob|
          glob = "#{ENV["HOME"]}/#{glob}" if glob[0] != ?/
          @count += Dir["#{glob}/*"].size
        end
      end
    end

    class Memory < Widget
      description "Various memory related data"
      attr_reader :total, :free, :buffers, :cached, :usage
      alias_method :default, :usage

      def init
        meminfo = ProcFile.new("meminfo")[0]
        @total = meminfo["MemTotal"].to_i
        @free = meminfo["MemFree"].to_i
        @buffers = meminfo["Buffers"].to_i
        @cached = meminfo["Cached"].to_i
        @usage = ((@total - @free - @cached - @buffers) * 100) / @total.to_f
      end
    end

    class Raggle < Widget
      description "Unread posts in raggle"
      attr_reader :unread
      alias_method :default, :unread

      def init
        feed_list = @options["feed_list_path"] || ".raggle/feeds.yaml"
        feed_list = "#{ENV["HOME"]}/#{feed_list}" if feed_list[0] != ?/
        feeds = YAML.load_file(feed_list)
        feed_cache = @options["feed_cache_path"] || ".raggle/feed_cache.store"
        feed_cache = "#{ENV["HOME"]}/#{feed_cache}" if feed_cache[0] != ?/
        cache = PStore.new(feed_cache)
        @unread = 0
        cache.transaction(false) do
          feeds.each do |feed|
            cache[feed["url"]].each do |item|
              @unread += 1 unless item["read?"]
            end
          end
        end
      end
    end
  end

  # Parse and manage command line options
  class Options
    include Enumerable

    def initialize(args)
      @options = {}
      @options[:config] = "#{ENV["HOME"]}/.amazing.yml"
      @options[:screens] = []
      @options[:loglevel] = "info"
      @options[:include] = []
      @options[:update] = []
      @args = args
      @parser = OptionParser.new do |opts|
        opts.on("-c", "--config FILE", "Configuration file (~/.amazing.yml)") do |config|
          @options[:config] = config
        end
        opts.on("-s", "--screen ID", "Screen ID (0)") do |screen|
          @options[:screens] << screen
        end
        opts.on("-l", "--log-level LEVEL", "Severity threshold (info)") do |level|
          @options[:loglevel] = level
        end
        opts.on("-i", "--include SCRIPT", "Include a widgets script") do |script|
          @options[:include] << script
        end
        opts.on("-u", "--update WIDGET", "Update a widget and exit") do |widget|
          @options[:update] << widget
        end
        opts.on("-w", "--list-widgets", "List available widgets") do
          @options[:listwidgets] = true
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

  # Command line interface runner
  #
  #   CLI.run(ARGV)
  class CLI
    def initialize(args)
      @args = args
      @log = Logger.new(STDOUT)
      @options = Options.new(@args)
    end

    def run
      trap("SIGINT") do
        @log.fatal("Received SIGINT, exiting")
        exit
      end
      @options.parse
      show_help if @options[:help]
      set_loglevel
      parse_config
      load_scripts
      list_widgets if @options[:listwidgets]
      setup_screens
      wait_for_sockets
      explicit_updates unless @options[:update].empty?
      update_non_interval
      count = 0
      loop do
        @config["widgets"].each do |widget_name, settings|
          if settings["every"] && count % settings["every"] == 0
            update_widget(widget_name)
          end
        end
        count += 1
        sleep 1
      end
    end

    private

    def show_help
      puts @options.help
      exit
    end

    def set_loglevel
      begin
        @log.level = Logger.const_get(@options[:loglevel].upcase)
      rescue NameError
        @log.error("Unsupported log level #{@options[:loglevel].inspect}")
        @log.level = Logger::INFO
      end
    end

    def load_scripts
      scripts = (@options[:include] + @config["include"]).uniq
      scripts.each do |script|
        begin
          Widgets.module_eval("require #{script.inspect}")
        rescue LoadError
          @log.error("No such widget script #{script.inspect}")
        end
      end
    end

    def list_widgets
      Widgets.constants.each do |widget|
        if description = Widgets.const_get(widget).description
          puts "#{widget}: #{description}"
        else
          puts widget
        end
      end
      exit
    end

    def parse_config
      @log.debug("Parsing configuration file")
      begin
        @config = YAML.load_file(@options[:config])
      rescue
        @log.fatal("Unable to parse configuration file, exiting")
        exit 1
      end
      @config["include"] ||= []
      @config["screens"] ||= []
    end

    def setup_screens
      @screens = {}
      @options[:screens].each do |screen|
        @screens[screen.to_i] = Awesome.new(screen)
      end
      if @screens.empty?
        @config["screens"].each do |screen|
          @screens[screen] = Awesome.new(screen)
        end
      end
      @screens[0] = Awesome.new if @screens.empty?
    end

    def wait_for_sockets
      @screens.each_key do |screen|
        @log.debug("Waiting for socket for screen #{screen}")
        begin
          Timeout.timeout(30) do
            sleep 1 until File.exist?("#{ENV["HOME"]}/.awesome_ctl.#{screen}")
            @log.debug("Got socket for screen #{screen}")
          end
        rescue Timeout::Error
          @log.fatal("Socket for screen #{screen} not created within 30 seconds, exiting")
          exit 1
        end
      end
    end

    def update_non_interval
      @config["widgets"].each do |widget_name, settings|
        next if settings["every"]
        update_widget(widget_name)
      end
    end

    def explicit_updates
      @config["widgets"].each_key do |widget_name|
        next unless @options[:update].include? widget_name
        update_widget(widget_name, false)
      end
      exit
    end

    def update_widget(widget_name, threaded=true)
      settings = @config["widgets"][widget_name]
      begin
        @screens.each do |screen, awesome|
          @log.debug("Updating widget #{widget_name} of type #{settings["type"]} on screen #{screen}")
          opts = settings["options"] || {}
          field = settings["field"] || "default"
          update = Proc.new do
            widget = Widgets.const_get(settings["type"]).new(opts)
            awesome.widget_tell(widget_name, widget.__send__(field))
          end
          if threaded
            Thread.new &update
          else
            update.call
          end
        end
      rescue WidgetError => e
        @log.error(settings["type"]) { e.message }
      end
    end
  end
end

if $0 == __FILE__
  Amazing::CLI.new(ARGV).run
end
