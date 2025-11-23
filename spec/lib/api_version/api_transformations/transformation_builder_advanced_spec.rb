require 'rails_helper'

RSpec.describe ApiVersion::ApiTransformations::TransformationBuilder do
  let(:item) do
    {
      user: { name: "John", age: 30 },
      items: [
        { id: 1, name: "Item 1" },
        { id: 2, name: "Item 2" }
      ],
      meta: { version: 1 },
      legacy_id: 123
    }
  end
  subject { described_class.new(item) }

  describe "advanced transformations" do
    describe "#nest" do
      it "applies transformations to a nested hash" do
        subject.nest(:user) do |u|
          u.rename_field :name, :full_name
        end
        expect(subject.build[:user][:full_name]).to eq("John")
        expect(subject.build[:user]).not_to have_key(:name)
      end

      it "does nothing if field is not a hash" do
        subject.nest(:legacy_id) { |l| l.add_field :new, default: 1 }
        expect(subject.build[:legacy_id]).to eq(123)
      end
    end

    describe "#each" do
      it "applies transformations to each element of an array" do
        subject.each(:items) do |i|
          i.add_field :active, default: true
        end
        expect(subject.build[:items].first[:active]).to be true
        expect(subject.build[:items].last[:active]).to be true
      end

      it "does nothing if field is not an array" do
        subject.each(:user) { |u| u.add_field :x, default: 1 }
        expect(subject.build[:user]).not_to have_key(:x)
      end
    end

    describe "#move_field" do
      it "moves a field to a nested location" do
        subject.move_field(:legacy_id, to: [ :meta, :id ])
        expect(subject.build[:meta][:id]).to eq(123)
        expect(subject.build).not_to have_key(:legacy_id)
      end

      it "creates intermediate keys if they don't exist" do
        subject.move_field(:legacy_id, to: [ :new_section, :deep, :id ])
        expect(subject.build[:new_section][:deep][:id]).to eq(123)
      end

      it "does nothing if field does not exist" do
        subject.move_field(:missing, to: [ :somewhere ])
        expect(subject.build).not_to have_key(:somewhere)
      end
    end
  end
end
