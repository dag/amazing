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

require 'socket'

module Amazing

  # Communicate with awesome
  #
  #   awesome = Awesome.new
  #   awesome.widget_tell(0, widget_id, "Hello, world")
  #   awesome = Awesome.new(1)
  #   awesome.tag_view(0, 3)
  #   Awesome.new.client_zoom
  class Awesome
    attr_accessor :screen, :display

    def initialize(display=0)
      @display = display
    end

    def method_missing(uicb, screen=0, *args)
      data = "#{screen} #{uicb} #{args.join(' ')}\n"
      __setup_socket__
      @socket.write(data)
    end

    private

    def __setup_socket__
      @socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_DGRAM, 0)
      @socket.connect(Socket.sockaddr_un("#{ENV["HOME"]}/.awesome_ctl.#@display"))
    end
  end
end
