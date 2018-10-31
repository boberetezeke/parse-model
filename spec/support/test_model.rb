class TestModel < ParseModel
  class_name "TestModel"

  attribute(:created_at,    :date)
  attribute(:updated_at,    :date)
  attribute(:integer_value, :integer)
  attribute(:string_value,  :string)
  attribute(:boolean_value, :boolean)

  has_many :test_instances
end

class TestInstance < ParseModel
  class_name "TestInstance"

  attribute(:instance_integer_value, :integer)
  attribute(:test_model_id, :pointer, pointer_class: TestModel)
end
