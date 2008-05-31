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
    class Sup < Widget
      description "Mail count in sup for the specified search terms"
      dependency "sup", "gem install sup, http://sup.rubyforge.org/"
      option :terms, "Search terms", "label:inbox -label:deleted -label:spam"
      field :count, "Number of messages matching search terms"
      default { @count }

      init do
        Redwood::Index.new
        Redwood::Index.load
        @count = Redwood::Index.index.search_each(@terms) {}
      end
    end
  end
end
