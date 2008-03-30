# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
    class ALSA < Widget
      description "Various data for the ALSA mixer"
      option :mixer, "ALSA mixer name", "Master"
      field :volume, "Volume in percentage", 0
      default { @volume }

      init do
        IO.popen("amixer get #@mixer", IO::RDONLY) do |am|
          out = am.read
          volumes = out.scan(/\[(\d+)%\]/).flatten
          volumes.each {|vol| @volume += vol.to_i }
          @volume = @volume / volumes.size
        end
      end
    end
  end
end
