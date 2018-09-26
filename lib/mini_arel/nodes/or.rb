module MiniArel
  module Nodes
    class Or < BinaryOp
      def value(record)
        @left_node.value(record) || @right_node.value(record)
      end

      def is_comparison?
        false
      end
    end
  end
end
