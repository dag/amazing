# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

begin
  require 'rubygems'
rescue LoadError
end

module Amazing
  module Widgets
    class Sup < Widget
      description "Mail count in sup for the specified search terms"
      dependency "sup", "gem install sup, http://sup.rubyforge.org/"
      option :terms, "Search terms", "label:inbox -label:deleted -label:spam"
      field :count, "Numer of messages matching search terms"
      default { @count }

      init do
        Redwood::Index.new
        Redwood::Index.load
        @count = Redwood::Index.index.search_each(@terms) {}
      end
    end
  end
end
