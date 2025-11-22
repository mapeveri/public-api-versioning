require 'rails_helper'

RSpec.describe ApiVersion::ApiTransformations::TransformationBuilder do
  let(:item) { { name: "John", age: 30, email: "john@example.com", full_name: "John Doe" } }
  subject { described_class.new(item) }

  describe "transformations" do
    describe "#add_field" do
      it "adds a field with a default value" do
        subject.add_field(:role, default: "guest")
        expect(subject.build[:role]).to eq("guest")
      end

      it "adds a field calculated by a block" do
        subject.add_field(:description) { |i| "#{i[:name]} is #{i[:age]}" }
        expect(subject.build[:description]).to eq("John is 30")
      end

      it "supports legacy second argument (ignored)" do
        subject.add_field(:legacy, :string, default: "value")
        expect(subject.build[:legacy]).to eq("value")
      end
    end

    describe "#change_to_mandatory" do
      it "does nothing if field exists" do
        subject.change_to_mandatory(:name, default: "Anonymous")
        expect(subject.build[:name]).to eq("John")
      end

      it "sets default value if field is missing" do
        subject.change_to_mandatory(:missing_field, default: "default_value")
        expect(subject.build[:missing_field]).to eq("default_value")
      end

      it "sets calculated value if field is missing" do
        subject.change_to_mandatory(:greeting) { |i| "Hello #{i[:name]}" }
        expect(subject.build[:greeting]).to eq("Hello John")
      end
    end

    describe "#remove_field" do
      it "removes an existing field" do
        subject.remove_field(:age)
        expect(subject.build).not_to have_key(:age)
      end

      it "does nothing if field does not exist" do
        subject.remove_field(:non_existent)
        expect(subject.build).to eq(item)
      end
    end

    describe "#rename_field" do
      it "renames an existing field" do
        subject.rename_field(:name, :first_name)
        expect(subject.build[:first_name]).to eq("John")
        expect(subject.build).not_to have_key(:name)
      end

      it "does nothing if old field does not exist" do
        subject.rename_field(:non_existent, :new_field)
        expect(subject.build).not_to have_key(:new_field)
      end
    end

    describe "#split_field" do
      it "splits a field into multiple fields" do
        subject.split_field(:full_name, into: [:fname, :lname])
        expect(subject.build[:fname]).to eq("John")
        expect(subject.build[:lname]).to eq("Doe")
        expect(subject.build).not_to have_key(:full_name)
      end

      it "does nothing if field is missing" do
        subject.split_field(:missing, into: [:a, :b])
        expect(subject.build).not_to have_key(:a)
      end
    end

    describe "#transform" do
      it "transforms a field value using a block" do
        subject.transform(:age) { |i| i[:age] * 2 }
        expect(subject.build[:age]).to eq(60)
      end
    end
  end
end
