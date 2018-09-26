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
      TestModel.create(integer_value: 1, string_value: 'abc', boolean_value: true)
    end

    it "does the count correctly" do
      expect(TestModel.all.size).to eq(1)
    end
  end
end
