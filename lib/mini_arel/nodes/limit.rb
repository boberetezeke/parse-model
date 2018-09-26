module MiniArel
  module Nodes
    class Limit < Terminal
      attr_reader :limit
      def initialize(limit)
        @limit = limit
      end
    end
  end
end
