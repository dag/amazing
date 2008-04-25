module Amazing
  module Helpers
    module PangoMarkup
      def span(text, opts)
        attrs = opts.map {|key, value| "#{key}=#{value.to_s.inspect}" }.join(" ")
        "<span #{attrs}>#{text}</span>"
      end

      def background(color, text)
        span(text, :background => color)
      end

      def foreground(color, text)
        span(text, :foreground => color)
      end

      def underline(text, style=:single)
        span(text, :underline => style)
      end

      def bold(text, level=:bold)
        span(text, :weight => level)
      end
    end
  end
end
