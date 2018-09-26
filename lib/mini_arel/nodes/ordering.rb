module MiniArel
  module Nodes
    class Ordering < Terminal
      attr_reader :order_str
      def initialize(order_str)
        @order_str = order_str
      end
    end
  end
end
