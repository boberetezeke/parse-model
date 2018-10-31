require 'spec_helper'
require 'parse_model'

describe ParseModel do
  before do
    parse_initialize
    load 'support/test_model.rb'
    parse_destroy_objects("TestModel")
    parse_destroy_objects("TestInstance")
  end

  context "when retrieving objects" do
    let!(:test_model) do
      test_model = ParseModel.client.object("TestModel")
      test_model["integerValue"] = 2
      test_model["stringValue"] = "a"
      test_model.save
      test_model
    end
    let!(:test_model_3) do
      test_model_3 = ParseModel.client.object("TestModel")
      test_model_3["integerValue"] = 3
      test_model_3["stringValue"] = "b"
      test_model_3.save
      test_model_3
    end
    let!(:test_model_4) do
      test_model_4 = ParseModel.client.object("TestModel")
      test_model_4["integerValue"] = 4
      test_model_4["stringValue"] = "b"
      test_model_4.save
      test_model_4
    end
    let!(:test_instance_10) do
      test_instance = ParseModel.client.object("TestInstance")
      test_instance["instanceIntegerValue"] = 10
      test_instance["testModelId"] = test_model["objectId"]
      test_instance.save
      test_instance
    end
    let!(:test_instance_11) do
      test_instance = ParseModel.client.object("TestInstance")
      test_instance["instanceIntegerValue"] = 11
      test_instance["testModelId"] = test_model["objectId"]
      test_instance.save
      test_instance
    end
    let!(:test_instance_13) do
      test_instance = ParseModel.client.object("TestInstance")
      test_instance["instanceIntegerValue"] = 13
      test_instance["testModelId"] = test_model_3["objectId"]
      test_instance.save
      test_instance
    end

    context "when running without a where clause" do
      it "does the all query correctly" do
        expect(TestModel.all.size).to eq(3)
        expect(TestModel.all.map(&:integer_value).sort).to eq([2,3,4])
      end

      it "does count query correctly" do
        expect(TestModel.count).to eq(3)
      end
    end

    context "when running with a where clause" do
      it "does an integer equal query correctly" do
        expect(TestModel.where(integer_value: 2).all.size).to eq(1)
      end

      it "does a string equal query correctly" do
        expect(TestModel.where(string_value: 'b').all.size).to eq(2)
      end

      it "does a integer and string equal query correctly" do
        expect(TestModel.where(integer_value: 3, string_value: 'b').all.size).to eq(1)
      end

      it "does a integer or string equal query correctly" do
        expect(
          TestModel.where(
            TestModel.arel_table[:integer_value].eq(3).or(
              TestModel.arel_table[:string_value].eq('a'))
          ).all.size).to eq(2)
      end

      it "does a integer and string greater than, less than comparison query correctly" do
        expect(
            TestModel.where(
                TestModel.arel_table[:integer_value].gteq(1).and(
                    TestModel.arel_table[:string_value].lt('b'))
            ).all.size).to eq(1)
      end

      it "does pointer comparisons correctly" do
        expect(TestInstance.where(test_model_id: test_model.id).all.size).to eq(2)
      end

      it "does count query correctly" do
        expect(TestModel.where(integer_value: 2).count).to eq(1)
      end
    end

    context "when running with a has_many" do
      it "allows retrieval of has_many relationships" do
        test_model = TestModel.where(integer_value: 2).first
        expect(test_model.test_instances.all.size).to eq(2)
      end
    end
  end
end
