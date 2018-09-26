require 'spec_helper'
require 'parse_model'

describe ParseModel do
  before do
    parse_initialize
    load 'support/test_model.rb'
    parse_destroy_objects("TestModel")
  end

  context "when retrieving objects" do
    before do
      test_model = ParseModel.client.object("TestModel")
      test_model["integerValue"] = 2
      test_model.save
      test_model = ParseModel.client.object("TestModel")
      test_model["integerValue"] = 3
      test_model.save
    end

    context "when running without a where clause" do
      it "does the all query correctly" do
        expect(TestModel.all.size).to eq(2)
        expect(TestModel.all.map(&:integer_value).sort).to eq([2,3])
      end

      it "does count query correctly" do
        expect(TestModel.count).to eq(2)
      end
    end

    context "when running without a where clause" do
      it "does the all query correctly" do
        expect(TestModel.where(integer_value: 2).all.size).to eq(1)
      end

      it "does count query correctly" do
        expect(TestModel.where(integer_value: 2).count).to eq(1)
      end
    end
  end
end
