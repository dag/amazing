# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

module Amazing
  class CLI
    module Commands
      private

      def cmd_show_help
        if @options[:help]
          puts @options.help
          exit
        end
      end

      def cmd_stop_process
        if @options[:stop]
          stop_process(false)
          exit
        end
      end

      def cmd_list_widgets
        if @options[:listwidgets]
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
      end

      def cmd_test_widget
        if @options[:test]
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
      end

      def cmd_explicit_updates
        if @options[:update] != []
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
      end

      def cmd_main
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
      end
    end
  end
end
