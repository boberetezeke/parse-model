module MiniArel
  class CollectionProxy
    def initialize(connection, owner, association)
      @connection = connection
      @owner = owner
      @association = association
    end

    def <<(collection)
      debug "CollectionProxy(owner: #{@owner})#<<(#{collection})"
      collection = [collection] unless collection.is_a?(Array)
      collection.each do |obj|
        obj.write_attribute(@association.foreign_key, @owner.id)
        obj.save
      end
    end

    def method_missing(sym, *args, &block)
      if [:first, :last, :all, :load, :reverse].include?(sym)
        where_clause = "#{@owner.table_name.singularize}_id"
        debug "#{sym}: for table: #{@association.table_name}, where: #{where_clause} == #{@owner.id}"
        Relation.new(@connection, @association.klass, @association.table_name).where(where_clause => @owner.id).send(sym)
      else
        super
      end
    end
  end
end
