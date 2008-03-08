# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'amazing/widget'

module Amazing
  module Widgets
    class Raggle < Widget
      description "Unread posts in raggle"
      dependency "pstore", "Ruby standard library"
      option :feed_list_path, "Path to feeds list", ".raggle/feeds.yaml"
      option :feed_cache_path, "Path to feeds cache", ".raggle/feed_cache.store"
      field :count, "Ammount of unread posts", 0
      default "@count"

      init do
        @feed_list_path = "#{ENV["HOME"]}/#@feed_list_path" if @feed_list_path[0] != ?/
        feeds = YAML.load_file(@feed_list_path)
        @feed_cache_path = "#{ENV["HOME"]}/#{@feed_cache_path}" if @feed_cache_path[0] != ?/
        cache = PStore.new(@feed_cache_path)
        cache.transaction(false) do
          feeds.each do |feed|
            cache[feed["url"]].each do |item|
              @count += 1 unless item["read?"]
            end
          end
        end
      end
    end
  end
end
