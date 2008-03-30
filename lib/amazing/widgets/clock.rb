# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
    class Clock < Widget
      description "Displays date and time"
      option :time_format, "Time format as described in DATE(1)", "%R"
      field :time, "Formatted time"
      default { @time }

      init do
        @time = Time.now.strftime(@time_format)
      end
    end
  end
end
