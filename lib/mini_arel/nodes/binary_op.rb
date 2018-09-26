module MiniArel
  module Nodes
    class BinaryOp
      attr_reader :left_node, :right_node
      def initialize(left_node, right_node)
        @left_node = left_node
        @right_node = right_node
      end

      def terminal?
        false
      end

      def is_comparison?
        true
      end

      def visit(context)
        @left_node.visit(context)
        @right_node.visit(context)

        binary_visit(context)
      end

      def or(node)
        MiniArel::Nodes::Or.new(self, node)
      end

      def and(node)
        MiniArel::Nodes::And.new(self, node)
      end

      def to_s
        "BinaryNode: #{self.class}: left:#{@left_node}, right:#{@right_node}"
      end
    end
  end
end
