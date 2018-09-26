module MiniArel
  class SelectManager
    attr_accessor :ordering, :limit, :offset
    attr_accessor :klass, :table_name, :node

    def initialize(connection, klass, table_name)
      @connection = connection
      @klass = klass
      @table_name = table_name
    end

    def where(node)
      @node = node
    end

    def execute
      @connection.execute(self)
    end
  end
end
