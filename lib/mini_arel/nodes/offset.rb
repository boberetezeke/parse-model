module MiniArel
  module Nodes
    class Offset < Terminal
      attr_reader :offset
      def initialize(offset)
        @offset = offset
      end
    end
  end
end
