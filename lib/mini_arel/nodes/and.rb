module MiniArel
  module Nodes
    class And < BinaryOp
      def value(record)
        @left_node.value(record) && @right_node.value(record)
      end

      def is_comparison?
        false
      end
    end
  end
end
