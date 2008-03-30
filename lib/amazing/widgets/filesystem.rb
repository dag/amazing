# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
    class Filesystem < Widget
      description "Various filesystem information"
      option :mountpoint, "Mountpoint for default format", "/"
      field :size, "Total size of volume in MB", {}
      field :used, "Size of used data in MB", {}
      field :free, "Size of free data in MB", {}
      field :percentage, "Percentage of used space", {}
      field :device, "Device name of mount point", {}
      default { @percentage[@mountpoint] }

      init do
        IO.popen("df") do |io|
          io.readlines[1..-1].map {|l| l.split }.each do |fs|
            @device[fs[5]] = fs[0].to_s
            @size[fs[5]] = fs[1].to_f / 1024
            @used[fs[5]] = fs[2].to_f / 1024
            @free[fs[5]] = fs[3].to_f / 1024
            @percentage[fs[5]] = fs[4].to_i
          end
        end
      end
    end
  end
end
