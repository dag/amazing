# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
    class Pacman < Widget
      description "Available upgrades in the Pacman package manager"
      option :pacman, "Path to the pacman program", "pacman"
      field :packages, "List of available upgrades", []
      field :count, "New package count", 0
      default "@count"

      init do
        IO.popen("#@pacman --query --upgrades") do |io|
          @packages = io.read.scan(/Targets: (.+)\n\n/m).to_s.split
          @count = @packages.size
        end
      end
    end
  end
end
