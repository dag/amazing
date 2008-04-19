# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'logger'
require 'amazing/options'
require 'amazing/x11/display_name'
require 'amazing/config'
require 'amazing/string'
require 'amazing/widget'
require 'amazing/proc_file'
require 'amazing/widgets'
require 'amazing/awesome'
require 'timeout'
require 'fileutils'
require 'thread'

module Amazing

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
      @threads = []
    end

    def run
      at_exit { Thread.list.each {|t| t.exit } }
      trap("SIGINT") do
        @log.fatal("Received SIGINT, exiting")
        remove_pid
        exit
      end
      @options.parse
      show_help if @options[:help]
      set_loglevel
      stop_process(true) if @options[:stop]
      load_scripts
      list_widgets if @options[:listwidgets]
      test_widget if @options[:test]
      parse_config
      wait_for_sockets
      @awesome = Awesome.new(@display.display)
      explicit_updates unless @options[:update] == []
      stop_process
      save_pid
      update_non_interval
      @config[:awesome].each do |awesome|
        awesome[:widgets].each do |widget|
          if widget[:interval]
            @threads << Thread.new(awesome, widget) do |awesome, widget|
              iteration = 1
              loop do
                Thread.new { update_widget(awesome[:screen], awesome[:statusbar], widget, iteration) }
                iteration += 1
                sleep widget[:interval]
              end
            end
          end
        end
      end
      @threads.each {|t| t.join }
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

    def stop_process(quit=false)
      begin
        Process.kill("SIGINT", File.read("#{ENV["HOME"]}/.amazing/pids/#{@display.display}.pid").to_i) 
        @log.warn("Killed older process") unless quit
      rescue
      end
      exit if quit
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

    def list_widgets
      if @options[:listwidgets] == true
        longest_widget_name = Widgets.constants.inject {|a,b| a.length > b.length ? a : b }.length
        Widgets.constants.sort.each do |widget|
          widget_class = Widgets.const_get(widget)
          puts "%-#{longest_widget_name}s : %s" % [widget, widget_class.description]
        end
      else
        widget_class = Widgets.const_get(@options[:listwidgets].camel_case)
        puts
        puts "#{@options[:listwidgets].camel_case} - #{widget_class.description}"
        puts
        dependencies = widget_class.dependencies
        unless dependencies.empty?
          longest_dependency_name = dependencies.keys.inject {|a,b| a.to_s.length > b.to_s.length ? a : b }.to_s.length
          longest_dependency_name = 10 if longest_dependency_name < 10
          longest_description = dependencies.values.inject {|a,b| a.length > b.length ? a : b }.length
          longest_description = 11 if longest_description < 11
          puts " %-#{longest_dependency_name}s | DESCRIPTION" % "DEPENDENCY"
          puts "-" * (longest_dependency_name + longest_description + 5)
          dependencies.keys.sort.each do |dependency|
            puts " %-#{longest_dependency_name}s | #{dependencies[dependency]}" % dependency
          end
          puts
        end
        options = widget_class.options
        unless options.empty?
          longest_option_name = options.keys.inject {|a,b| a.to_s.length > b.to_s.length ? a : b }.to_s.length
          longest_option_name = 6 if longest_option_name < 6
          longest_description = options.values.inject {|a,b| a[:description].length > b[:description].length ? a : b }[:description].length
          longest_description = 11 if longest_description < 11
          longest_default = options.values.inject {|a,b| a[:default].inspect.length > b[:default].inspect.length ? a : b }[:default].inspect.length
          longest_default = 7 if longest_default < 7
          puts " %-#{longest_option_name}s | %-#{longest_description}s | DEFAULT" % ["OPTION", "DESCRIPTION"]
          puts "-" * (longest_option_name + longest_description + longest_default + 8)
          options.keys.sort_by {|option| option.to_s }.each do |option|
            puts " %-#{longest_option_name}s | %-#{longest_description}s | %s" % [option, options[option][:description], options[option][:default].inspect]
          end
          puts
        end
        fields = widget_class.fields
        unless fields.empty?
          longest_field_name = fields.keys.inject {|a,b| a.to_s.length > b.to_s.length ? a : b }.to_s.length
          longest_field_name = 5 if longest_field_name < 5
          longest_description = fields.values.inject {|a,b| a[:description].length > b[:description].length ? a : b }[:description].length
          longest_description = 11 if longest_description < 11
          longest_default = fields.values.inject {|a,b| a[:default].inspect.length > b[:default].inspect.length ? a : b }[:default].inspect.length
          longest_default = 7 if longest_default < 7
          puts " %-#{longest_field_name + 1}s | %-#{longest_description}s | DEFAULT" % ["FIELD", "DESCRIPTION"]
          puts "-" * (longest_field_name + longest_description + longest_default + 9)
          fields.keys.sort_by {|field| field.to_s }.each do |field|
            puts " @%-#{longest_field_name}s | %-#{longest_description}s | %s" % [field, fields[field][:description], fields[field][:default].inspect]
          end
          puts
        end
      end
      exit
    end

    def test_widget
      widget = Widgets.const_get(@options[:test].camel_case)
      settings = YAML.load("{#{ARGV[0]}}")
      instance = widget.new(settings)
      longest_field_name = widget.fields.merge({:default => nil}).keys.inject {|a,b| a.to_s.length > b.to_s.length ? a : b }.to_s.length
      puts "@%-#{longest_field_name}s = %s" % [:default, instance.instance_variable_get(:@default).inspect]
      widget.fields.keys.sort_by {|field| field.to_s }.each do |field|
        puts "@%-#{longest_field_name}s = %s" % [field, instance.instance_variable_get("@#{field}".to_sym).inspect]
      end
      exit
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

    def explicit_updates
      @config[:awesome].each do |awesome|
        awesome[:widgets].each do |widget|
          locator = "%s/%s/%s" % [widget[:identifier], awesome[:statusbar], awesome[:screen]]
          next unless @options[:update] == :all || @options[:update].include?(locator)
          @threads << Thread.new(awesome, widget) do |awesome, widget|
            update_widget(awesome[:screen], awesome[:statusbar], widget)
          end
        end
      end
      @threads.each {|t| t.join }
      exit
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

    def update_non_interval
      @config[:awesome].each do |awesome|
        awesome[:widgets].each do |widget|
          next if widget[:interval]
          @threads << Thread.new(awesome, widget) do |awesome, widget|
            update_widget(awesome[:screen], awesome[:statusbar], widget)
          end
        end
      end
      @threads.each {|t| t.join }
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
  end
end
