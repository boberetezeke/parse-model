require "active_model"
require "parse-ruby-client"
require_relative "mini_arel"

class ParseModel
  include ActiveModel::Model

  class Attribute
    attr_reader :name, :type, :extra

    def initialize(name, type, pointer_class: nil, camelized_name: nil, extra: nil)
      @name = name
      @type = type
      @pointer_class = pointer_class
      @camelized_name = camelized_name
      @extra = extra
    end

    def camelized_name
      return @camelized_name if @camelized_name

      camelized_name = @name.to_s.camelize
      camelized_name[0..0].downcase + camelized_name[1..-1]
    end

    def to_parse_value(value)
      return value if value.nil?

      if @type == :datetime || @type == :date
        {
          "__type" => "Date",
          "iso" => value.iso8601
        }
      elsif @type == :integer
        if value == ""
          nil
        else
          value.to_i
        end
      elsif @type == :pointer
        Parse::Pointer.new("className" => @pointer_class, "objectId" => value)
      elsif @type == :boolean
        value ? true : false
      else
        value
      end
    end

    def migrate_value
      if @type == :datetime || @type == :date
        Time.now
      elsif @type == :integer
        0
      elsif @type == :boolean
        true
      else
        ""
      end
    end

    def from_parse_value(value)
      return nil if value.nil?

      if @type == :datetime || @type == :date
        value.to_time
      elsif @type == :pointer
      #  value["className"].constantize.find(value["objectId"])
      #  value.className.constantize.find(value.parse_object_id)
        if value.is_a?(Parse::Pointer)
          value = value.parse_object_id
        else
          value
        end
      else
        value
      end
    end

    def set(parse_object, value)
      parse_object[camelized_name]=(to_parse_value(value))
    end

    def get(parse_object)
      from_parse_value(parse_object[camelized_name])
    end

    def eq(value)
      MiniArel::Nodes::Equality.new(MiniArel::Nodes::Symbol.new(name), MiniArel::Nodes::Literal.new(value))
    end

    def not_eq(value)
      MiniArel::Nodes::NotEqual.new(MiniArel::Nodes::Symbol.new(name), MiniArel::Nodes::Literal.new(value))
    end

    def gt(value)
      MiniArel::Nodes::GreaterThan.new(MiniArel::Nodes::Symbol.new(name), MiniArel::Nodes::Literal.new(value))
    end

    def gteq(value)
      MiniArel::Nodes::GreaterThanOrEqual.new(MiniArel::Nodes::Symbol.new(name), MiniArel::Nodes::Literal.new(value))
    end

    def lt(value)
      MiniArel::Nodes::LessThan.new(MiniArel::Nodes::Symbol.new(name), MiniArel::Nodes::Literal.new(value))
    end

    def lteq(value)
      MiniArel::Nodes::LessThanOrEqual.new(MiniArel::Nodes::Symbol.new(name), MiniArel::Nodes::Literal.new(value))
    end

    def regex(value, options: nil)
      MiniArel::Nodes::RegexMatch.new(MiniArel::Nodes::Symbol.new(name), MiniArel::Nodes::Literal.new(value), options: options)
    end

    def in(value)
      MiniArel::Nodes::In.new(MiniArel::Nodes::Symbol.new(name), MiniArel::Nodes::Literal.new(value))
    end
  end

  class Association
    attr_reader :name, :type, :class_name

    def initialize(container_klass, name, type, class_name: nil, foreign_key: nil)
      @name = name
      @type = type
      @container_klass = container_klass
      @class_name = class_name || name.to_s.singularize.camelize
      @foreign_key = foreign_key
    end

    def klass
      @klass || @klass = @class_name.constantize
    end

    def macro
      @type
    end

    def foreign_key
      return @foreign_key if @foreign_key
      if @type == :has_many
        @foreign_key = "#{@container_klass.to_s.underscore}_id"
      else
        @foreign_key = "#{@class_name.to_s.underscore}_id"
      end
    end

    def get(object)
      if @type == :has_many
        relation = MiniArel::Relation.new(klass, klass, klass.parse_class_name)
        relation.where({foreign_key => object.id})
      else
        relation = MiniArel::Relation.new(klass, klass, klass.parse_class_name)
        relation.where({objectId: object.send(foreign_key)}).first
      end
    end

    def set(object, target)
      if @type == :has_many
      else
        object.send("#{foreign_key}=", target.id)
      end
    end
  end

  class ArelTable
    def initialize(klass)
      @klass = klass
    end

    def [](attr)
      @klass.attributes[attr]
    end
  end

  def self.initialize(application_id: nil, host: nil, master_key: nil, logger: nil, logger_level: Logger::ERROR)
    return if defined?(@@initialized)

    application_id ||= ENV['PARSE_APPLICATION_ID']
    host ||= ENV['PARSE_HOST']
    master_key ||= ENV['PARSE_MASTER_KEY']
    logger = Logger.new(STDERR).tap { |l| l.level = logger_level } unless logger
    @logger = logger

    logger.info "parse host: #{host}"
    # Parse.init :application_id => ENV['PARSE_APPLICATION_ID'], :api_key => ENV['PARSE_API_KEY']
    @@client = Parse.create :application_id => application_id, :host => host, :master_key =>  master_key, :logger => logger
    @@initialized = true
  end

  def self.logger
    @logger
  end

  def self.log(str)
    @logger.debug "** ParseModel ** :[#{str}]"
  end

  def self.client
    initialize
    @@client
  end

  # methods for sub-classes
  def self.attribute(name, type, pointer_class: nil, camelized_name: nil, extra: nil)
    if !@attributes
      @attributes = {}
      attribute :created_at, :datetime
      attribute :updated_at, :datetime
      attribute :object_id,  :datetime
    end
    @attributes[name] = Attribute.new(name, type, pointer_class: pointer_class, camelized_name: camelized_name, extra: extra)
  end

  def self.has_many(sym, **hargs)
    @associations ||= {}
    @associations[sym] = Association.new(self, sym, :has_many, **hargs)
  end

  def self.belongs_to(sym, **hargs)
    @associations ||= {}
    association = Association.new(self, sym, :belongs_to, **hargs)
    @associations[sym] = association
    attribute(association.foreign_key.to_sym, :string)
    # attribute(association.foreign_key.to_sym, :pointer, pointer_class: self)
  end

  def self.table_name(name)
    self.initialize
    @parse_class_name = name
  end

  # accessor methods
  def self.attributes
    @attributes
  end

  def self.associations
    @associations
  end

  def self.parse_class_name
    @parse_class_name || self.to_s
  end

  def self.camelize(symbol)
    symbol = symbol.to_s.camelize
    symbol[0..0].downcase + symbol[1..-1]
  end

  def self.visit(node, select_manager)
    ParseModel.log "visit #{node}"
    if node.nil?
      ParseModel.log "visit node.nil?"
      return select_manager.query
    elsif !(node.terminal?)
      ParseModel.log "visit !(node.terminal?)"
      query1 = visit(node.left_node, select_manager)
      ParseModel.log "visit query1 #{query1}"
      query2 = visit(node.right_node, select_manager)
      ParseModel.log "visit query2 #{query1}"

      if node.is_comparison?
        if node.left_node.is_a?(MiniArel::Nodes::Symbol) && node.right_node.is_a?(MiniArel::Nodes::Literal)
          symbol = node.left_node.value
          literal = node.right_node.value
        elsif node.right_node.is_a?(MiniArel::Nodes::Symbol) && node.left_node.is_a?(MiniArel::Nodes::Literal)
          symbol = node.right_node.value
          literal = node.left_node.value
        else
          raise "one node should be a symbol and one a literal: #{node.left_node.class}, #{node.right_node.class}"
        end

        symbol = camelize(symbol)
        query = select_manager.query
        if node.is_a?(MiniArel::Nodes::Equality)
          ParseModel.log "query.eq(#{symbol}, #{literal})"
          query.eq(symbol, literal)
        elsif node.is_a?(MiniArel::Nodes::NotEqual)
          ParseModel.log "query.not_eq(#{symbol}, #{literal})"
          query.not_eq(symbol, literal)
        elsif node.is_a?(MiniArel::Nodes::RegexMatch)
          ParseModel.log "query.regex_match(#{symbol}, #{literal})"
          query.regex(symbol, literal, options: node.options)
        elsif node.is_a?(MiniArel::Nodes::In)
          ParseModel.log "query.value_in(#{symbol}, #{literal})"
          query.value_in(symbol, literal)
        elsif node.is_a?(MiniArel::Nodes::GreaterThan)
          ParseModel.log "query.greater_than(#{symbol}, #{literal})"
          query.greater_than(symbol, literal)
        elsif node.is_a?(MiniArel::Nodes::GreaterThanOrEqual)
          ParseModel.log "query.greater_eq(#{symbol}, #{literal})"
          query.greater_eq(symbol, literal)
        elsif node.is_a?(MiniArel::Nodes::LessThan)
          ParseModel.log "query.less_than(#{symbol}, #{literal})"
          query.less_than(symbol, literal)
        elsif node.is_a?(MiniArel::Nodes::LessThanOrEqual)
          ParseModel.log "query.less_eq(#{symbol}, #{literal})"
          query.less_eq(symbol, literal)
        #elsif node.is_a?(MiniArel::Nodes::ValueIn)
        #  query.value_in(symbol_node.value.to_s, literal_node.value)
        #elsif node.is_a?(MiniArel::Nodes::ValueNotIn)
        #  query.value_not_in(symbol_node.value.to_s, literal_node.value)
        end
      elsif node.is_a?(MiniArel::Nodes::Or)
        query = query1
        query.or(query2)
        ParseModel.log "query(#{query1}).or(#{query2})"
      elsif node.is_a?(MiniArel::Nodes::And)
        ParseModel.log "query(#{query}).and"
        query = query1
        (query.where.keys + query2.where.keys).uniq.each do |k|
          if query.where[k] && query2.where[k]
            query.where[k].merge!(query2.where[k])
          elsif query2.where[k]
            query.where[k] = query2.where[k]
          end
        end
        # puts "query.where = #{query.where}"
      end

      return query
    end
  end

  def self.set_options(query, select_manager)
    query.limit = select_manager.limit.limit if select_manager.limit
    query.skip = select_manager.offset.offset if select_manager.offset
    query.count if select_manager.count
    if select_manager.ordering
      order_str = select_manager.ordering.order_str
      if m = /(\w+)\s+(DESC|ASC)/.match(order_str)
        order_by = m[1].underscore
        order_direction = (m[2] == "DESC") ? :descending : :ascending
      else
        order_by = order_str.underscore
        order_direction = "ascending"
      end
      query.order_by = camelize(order_by)
      query.order = order_direction
    end
  end

  def self.execute(select_manager)
    options = {}
    query = visit(select_manager.node, select_manager)


    if pointer_comparisons
      pointer_name = pointer_comparisons.keys.first
      pointer_values = pointer_comparisons[pointer_name]

      if pointer_values.size > 0
        query.eq(pointer_name, pointer_values[0])
      end

      if pointer_values.size == 2
        query2 = visit(select_manager.node, options)
        query2.eq(pointer_name, pointer_values[1])
        query.or(query2)
      elsif pointer_values.size > 2
       raise "maximum 2 facilities allowed"
      end
    end

    set_options(query, select_manager)

    wrap_result(query.get)
  end

  def self.pointer_comparisons
    @pointer_comparisons
  end

  def self.pointer_comparisons=(pc)
    @pointer_comparisons = pc
  end

  # query methods
  def self.where(*args)
    relation = MiniArel::Relation.new(self, self, parse_class_name)
    relation = relation.where(*args) if args != [{}]
    relation
  end

  def self.find(id)
    where(object_id: id).first
  end

  def self.arel_table
    ArelTable.new(self)
  end

  def self.wrap_result(result)
    if result.is_a?(Hash)
      result["count"]
    else
      result.map do |r|
        r = self.new(r)
        r.after_load
        r
      end
    end
  end

  def self.query(class_name)
    client.query(class_name)
  end

  def self.before_save(*args)
    raise "only one argument allowed for before_save" if args.size != 1

    @save_callback = args.first
  end

  def self.invoke_before_save_callback(instance)
    return unless @save_callback

    if @save_callback.is_a?(Symbol)
      instance.send(@save_callback)
    elsif @save_callback.is?(Proc)
      @save_callback.call(instance)
    end
  end

  def self.create(*args)
    obj = self.new(*args)
    obj.save
    obj
  end

  def self.migrate
    object = self.new
    attributes.values.each do |attr|
      object.send("#{attr.name}=", attr.migrate_value)
    end
    object.save
    object.destroy
  end

  def self.method_missing(sym, *args)
    if [:first, :last, :all, :count, :where, :limit, :order, :offset].include?(sym)
      MiniArel::Relation.new(self, self, parse_class_name).send(sym, *args)
    else
      super
    end
  end

  attr_reader :parse_object

  def initialize(parse_object=nil)
    if parse_object.is_a?(Parse::Object)
      @parse_object = parse_object
    else
      po = ParseModel.client.object(self.class.parse_class_name)
      @parse_object = po
      parse_object.each { |k,v| self.send("#{k}=", v) } if parse_object
    end
  end

  def id
    @parse_object['objectId']
  end

  def save
    if valid?
      self.class.invoke_before_save_callback(self)
      @parse_object.save
      true
    else
      false
    end
  end

  def update(params)
    params.each { |k,v| self.send("#{k}=", v) }
    save
  end

  # stub for handling objects when they are returned from a query
  def after_load
  end

  def persisted?
    self.id.present?
  end

  def reload
    persisted_object = self.class.find(self.id)
    @parse_object = persisted_object.parse_object
    self
  end

  def destroy
    @parse_object.parse_delete
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    if self.persisted? && other.persisted?
      self.id == other.id
    elsif !self.persisted? && !other.persisted?
      @parse_object == other.parse_object
    else
      false
    end
  end

  def to_s
    @parse_object.to_s
  end

  def method_missing(sym, *args, &block)
    attribute = nil
    action = nil
    if (m = /^(.*)=$/.match(sym.to_s)) && args.size == 1
      attribute_name = m[1]
      value = args.shift
      action = :set
    elsif args.size == 0
      attribute_name = sym.to_s
      action = :get
    end

    if attribute_name
      attribute_sym = attribute_name.to_sym

      attribute = self.class.attributes[attribute_sym]
      return (action == :set) ? attribute.set(@parse_object, value) : attribute.get(@parse_object) if attribute

      association = self.class.associations[attribute_sym]
      return (action == :set) ? association.set(self, value) : association.get(self) if association
    end

    super(sym, *args, &block)
  end
end
