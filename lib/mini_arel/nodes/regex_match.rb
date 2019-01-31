module MiniArel
  module Nodes
    class RegexMatch < BinaryOp
      attr_reader :options
      def initialize(left_op, right_op, options: nil)
        super(left_op, right_op)

        @options = options
      end

      def value(record)
        @left_node.value(record) =~ @right_node.value(record)
      end
    end
  end
end
