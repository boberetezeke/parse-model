module MiniArel
  class SelectManager
    attr_accessor :ordering, :limit, :offset
    attr_accessor :klass, :table_name, :node, :count

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

    def query
      ParseModel.log "SelectManager: query for #{@connection} on table: #{@table_name}"
      @connection.query(@table_name)
    end
  end
end
