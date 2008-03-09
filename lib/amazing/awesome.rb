# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'socket'

module Amazing

  # Communicate with awesome
  #
  #   awesome = Awesome.new
  #   awesome.widget_tell(widget_id, "Hello, world")
  #   awesome = Awesome.new(1)
  #   awesome.tag_view(3)
  #   Awesome.new.client_zoom
  class Awesome
    attr_accessor :screen, :display

    def initialize(screen=0, display=0)
      @screen = screen.to_i
      @display = display
      __setup_socket__
    end

    def method_missing(method, *args)
      data = "#@screen #{method} #{args.join(' ')}\n"
      begin
        @socket.write(data)
      rescue Errno::ECONNREFUSED, Errno::ENOTCONN
        __setup_socket__
        @socket.write(data)
      end
    end

    private

    def __setup_socket__
      @socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_DGRAM, 0)
      @socket.connect(Socket.sockaddr_un("#{ENV["HOME"]}/.awesome_ctl.#@display"))
    end
  end
end
