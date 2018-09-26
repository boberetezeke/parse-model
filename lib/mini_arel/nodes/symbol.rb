module MiniArel
  module Nodes
    class Symbol < Terminal
      def initialize(symbol)
        @symbol = symbol
      end

      def value
        @symbol
      end

      def to_s
        "Symbol: #{@symbol}"
      end
    end
  end
end
