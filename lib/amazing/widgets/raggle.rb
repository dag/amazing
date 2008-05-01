# Copyright 2008 Dag Odenhall <dag.odenhall@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'amazing/widget'

module Amazing
  module Widgets
    class Raggle < Widget
      description "Unread posts in raggle"
      dependency "pstore", "Ruby standard library"
      option :feed_list_path, "Path to feeds list", "~/.raggle/feeds.yaml"
      option :feed_cache_path, "Path to feeds cache", "~/.raggle/feed_cache.store"
      field :count, "Ammount of unread posts", 0
      default { @count }

      init do
        @feed_list_path = ::File.expand_path(@feed_list_path, "~")
        feeds = YAML.load_file(@feed_list_path)
        @feed_cache_path = ::File.expand_path(@feed_cache_path, "~")
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
