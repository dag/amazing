# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
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
  end
end
