class TestModel < ParseModel
  class_name "TestModel"

  attribute(:created_at,    :date)
  attribute(:updated_at,    :date)
  attribute(:integer_value, :integer)
  attribute(:string_value,  :string)
  attribute(:boolean_value, :boolean)
end
