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
#       format: ruby code
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
#         time_format: %T
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
#   class Clock < Widget
#     description "Displays date and time"
#     dependency "some/library", "how to get the library (url, gem name...)"
#     option :time_format, "Time format as described in DATE(1)", "%R"
#     field :time, "Formatted time"
#     default "@time"
# 
#     init do
#       @time = Time.now.strftime(@time_format)
#       raise WidgetError, "An error occured!" if some_error?
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
# * Self-documenting widgets (list fields and options) (done in widgets)
# * Some widgets need to support multiple data sources
# * Some way to do alerts, e.g. "blinking"
# * Make widget configuration screen specific
# * Support widgets with multiple bars and graphs (maybe wait for 2.3)
# * Maybe keep custom widget options at same level as other options
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
require 'socket'
require 'pstore'

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

  # Communicate with awesome
  #
  #   awesome = Awesome.new
  #   awesome.widget_tell(widget_id, "Hello, world")
  #   awesome = Awesome.new(1)
  #   awesome.tag_view(3)
  #   Awesome.new.client_zoom
  class Awesome
    attr_accessor :screen, :display

    def initialize(screen=0, display=0)
      @screen = screen.to_i
      @display = display
      @socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_DGRAM, 0)
      @socket.connect(Socket.sockaddr_un("#{ENV["HOME"]}/.awesome_ctl.#@display"))
    end

    def method_missing(method, *args)
      @socket.write("#@screen #{method} #{args.join(' ')}\n")
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

  # Parent class for widget construction, example:
  #
  #   class Clock < Widget
  #     description "Displays date and time"
  #     dependency "some/library", "how to get the library (url, gem name...)"
  #     option :time_format, "Time format as described in DATE(1)", "%R"
  #     field :time, "Formatted time"
  #     default "@time"
  # 
  #     init do
  #       @time = Time.now.strftime(@time_format)
  #       raise WidgetError, "An error occured!" if some_error?
  #     end
  #   end
  class Widget
    def initialize(identifier=nil, format=nil, opts={})
      self.class.dependencies.each do |name, description|
        begin
          require name
        rescue LoadError
          raise WidgetError, "Missing dependency #{name.inspect}#{if description then " [#{description}]" end}"
        end
      end
      @identifier, @format = identifier, format
      self.class.options.each do |key, value|
        value = opts[key.to_s] || value[:default]
        instance_variable_set "@#{key}".to_sym, value
      end
      self.class.fields.each do |key, value|
        instance_variable_set "@#{key}".to_sym, value[:default]
      end
      instance_eval(&self.class.init) if self.class.init
    end

    def self.description(description=nil)
      if description
        @description = description
      else
        @description
      end
    end

    def self.dependency(name, description=nil)
      @dependencies ||= {}
      @dependencies[name] = description
    end

    def self.dependencies
      @dependencies || {}
    end

    def self.option(name, description=nil, default=nil)
      @options ||= {}
      @options[name] = {:description => description, :default => default}
    end

    def self.options
      @options || {}
    end

    def self.field(name, description=nil, default=nil)
      @fields ||= {}
      @fields[name] = {:description => description, :default => default}
    end

    def self.fields
      @fields || {}
    end

    def self.default(format=nil, &block)
      if format
        @default = format
      elsif block
        @default = block
      else
        @default
      end
    end

    def self.init(&block)
      if block
        @init = block
      else
        @init
      end
    end

    def formatize
      if @format
        instance_eval(@format)
      else
        case self.class.default
        when Proc
          instance_eval(&self.class.default)
        when String
          instance_eval(self.class.default)
        end
      end
    end
  end

  module Widgets
    class ALSA < Widget
      description "Various data for the ALSA mixer"
      option :mixer, "ALSA mixer name", "Master"
      field :volume, "Volume in percentage", 0
      default "@volume"

      init do
        IO.popen("amixer get #@mixer", IO::RDONLY) do |am|
          out = am.read
          volumes = out.scan(/\[(\d+)%\]/).flatten
          volumes.each {|vol| @volume += vol.to_i }
          @volume = @volume / volumes.size
        end
      end
    end

    class Battery < Widget
      description "Remaining battery power in percentage"
      option :battery, "Battery number", 1
      field :percentage, "Power percentage", 0
      default "@percentage"

      init do
        batinfo = ProcFile.new("acpi/battery/BAT#@battery/info")[0]
        batstate = ProcFile.new("acpi/battery/BAT#@battery/state")[0]
        remaining = batstate["remaining capacity"].to_i
        lastfull = batinfo["last full capacity"].to_i
        @percentage = (remaining * 100) / lastfull.to_f
      end
    end

    class Clock < Widget
      description "Displays date and time"
      option :time_format, "Time format as described in DATE(1)", "%R"
      field :time, "Formatted time"
      default "@time"

      init do
        @time = Time.now.strftime(@time_format)
      end
    end

    class Maildir < Widget
      description "Mail count in maildirs"
      option :directories, "Globs of maildirs" # TODO: does a default make sense?
      field :count, "Ammount of mail in searched directories", 0
      default "@count"

      init do
        raise WidgetError, "No directories configured" unless @directories
        @directories.each do |glob|
          glob = "#{ENV["HOME"]}/#{glob}" if glob[0] != ?/
          @count += Dir["#{glob}/*"].size
        end
      end
    end

    class Memory < Widget
      description "Various memory related data"
      field :total, "Total kilobytes of memory", 0
      field :free, "Free kilobytes of memory", 0
      field :buffers, nil, 0 # TODO: description
      field :cached, nil, 0 # TODO: description
      field :usage, "Percentage of used memory", 0
      default "@usage"

      init do
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
      option :feed_list_path, "Path to feeds list", ".raggle/feeds.yaml"
      option :feed_cache_path, "Path to feeds cache", ".raggle/feed_cache.store"
      field :count, "Ammount of unread posts", 0
      default "@count"

      init do
        @feed_list_path = "#{ENV["HOME"]}/#@feed_list_path" if @feed_list_path[0] != ?/
        feeds = YAML.load_file(@feed_list_path)
        @feed_cache_path = "#{ENV["HOME"]}/#{@feed_cache_path}" if @feed_cache_path[0] != ?/
        cache = PStore.new(@feed_cache_path)
        cache.transaction(false) do
          feeds.each do |feed|
            cache[feed["url"]].each do |item|
              @count += 1 unless item["read?"]
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
      scripts = @options[:include]
      @config["include"].each do |script|
        script = "#{File.dirname(@options[:config])}/#{script}" if script[0] != ?/
        scripts << script
      end
      scripts.each do |script|
        if File.exist?(script)
          Widgets.module_eval(File.read(script))
        else
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
        @screens[screen.to_i] = Awesome.new(screen, @display.display)
      end
      if @screens.empty?
        @config["screens"].each do |screen|
          @screens[screen] = Awesome.new(screen, @display.display)
        end
      end
      @screens[0] = Awesome.new if @screens.empty?
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
            widget = Widgets.const_get(settings["type"]).new(widget_name, settings["format"], opts)
            awesome.widget_tell(widget_name, widget.formatize)
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
