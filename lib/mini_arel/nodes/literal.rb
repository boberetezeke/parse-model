module MiniArel
  module Nodes
    class Literal < Terminal
      def initialize(value)
        @value = value
      end

      def value
        @value
      end

      def to_s
        "Literal: #{@value}"
      end
    end
  end
end

