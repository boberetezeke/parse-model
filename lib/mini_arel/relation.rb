module MiniArel
  class Relation
    def initialize(connection, klass, table_name)
      @select_manager = MiniArel::SelectManager.new(connection, klass, table_name)
    end

    def execute
      @records = @select_manager.execute
    end

    def where(query)
      if query.is_a?(MiniArel::Nodes::BinaryOp)
        node = query
      else
        key, value = query.first
        node = eq_node(key, value)
        if query.keys.size > 1
          query.to_a[1..-1].each do |key, value|
            node = MiniArel::Nodes::And.new(node, eq_node(key, value))
          end
        end
      end

      @select_manager.where(node)
      self
    end

    def order(order_str)
      @select_manager.ordering = MiniArel::Nodes::Ordering.new(order_str)
      self
    end

    def limit(num)
      @select_manager.limit = MiniArel::Nodes::Limit.new(num)
      self
    end

    def offset(index)
      @select_manager.offset = MiniArel::Nodes::Offset.new(index)
      self
    end

    def first
      execute.first
    end

    def last
      execute.last
    end

    def reverse
      execute.reverse
    end

    def [](index)
      execute[index]
    end

    def all
      execute
    end

    alias load all

    def each
      execute.each { |record| yield record }
    end

    def eq_node(key, value)
      MiniArel::Nodes::Equality.new(MiniArel::Nodes::Symbol.new(key), MiniArel::Nodes::Literal.new(value))
    end
  end
end
