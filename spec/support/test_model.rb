class TestModel < ParseModel
  table_name "TestModel"

  attribute(:integer_value, :integer)
  attribute(:string_value,  :string)
  attribute(:boolean_value, :boolean)

  has_many :test_instances
end

class TestInstance < ParseModel
  table_name "TestInstance"

  attribute(:instance_integer_value, :integer)

  belongs_to :test_model
end
