module MiniArel
  module Nodes
    class In < BinaryOp
      def value(record)
        @left_node.value(record).include?(@right_node.value(record))
      end
    end
  end
end
