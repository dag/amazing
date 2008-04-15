# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
    class CpuUsage < Widget
      description "CPU usage"
      option :cpu, "CPU number, 0 is all", 0
      field :usage, "Percent of CPU in use", []
      default { @usage[@cpu].to_i }

      init do
        first = gather_data()
        sleep 1
        second = gather_data()
        first.each_index do |cpunum|
          idle = second[cpunum][3].to_i - first[cpunum][3].to_i
          sum = second[cpunum][0..5].inject {|a,b| a.to_i + b.to_i } -
            first[cpunum][0..5].inject {|a,b| a.to_i + b.to_i }
          @usage[cpunum] = 100 - (idle * 100) / sum.to_f
        end
      end

      private

      def gather_data
        cpus = []
        ::File.readlines("/proc/stat").select {|l| l =~ /^cpu/ }.each do |l|
          l = l.split
          cpunum = l[0] == "cpu" ? 0 : l[0].scan(/\d+/)[0].to_i + 1
          cpus[cpunum] = l[1..-1]
        end
        cpus
      end
    end
  end
end
