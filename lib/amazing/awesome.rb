# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

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
