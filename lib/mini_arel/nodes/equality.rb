module MiniArel
  module Nodes
    class Equality < BinaryOp
      def value(record)
        @left_node.value(record) == @right_node.value(record)
      end
    end
  end
end
