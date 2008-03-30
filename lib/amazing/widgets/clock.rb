# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
    class Clock < Widget
      description "Displays date and time"
      option :time_format, "Time format as described in DATE(1)", "%R"
      option :offset, "UTC offset in hours", Time.now.utc_offset / 3600
      field :time, "Formatted time"
      default { @time }

      init do
        @time = (Time.now.utc + @offset.to_f * 3600).strftime(@time_format)
      end
    end
  end
end
