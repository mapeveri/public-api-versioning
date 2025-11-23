require 'rails_helper'

RSpec.describe ApiVersion::ApiTransformations::TransformationBuilder do
  let(:item) { { name: "John", meta: { id: 123, tracking: { code: "XYZ" } } } }
  subject { described_class.new(item) }

  describe "#nest" do
    it "nests fields under a new key" do
      subject.nest(:meta) do |builder|
        builder.add_field(:version, default: 1)
      end
      expect(subject.build[:meta][:version]).to eq(1)
    end
  end

  describe "#each" do
    let(:item) { { items: [{ id: 1 }, { id: 2 }] } }

    it "iterates over a collection" do
      subject.each(:items) do |builder|
        builder.add_field(:active, default: true)
      end
      expect(subject.build[:items].first[:active]).to be(true)
    end
  end

  describe "#move_field" do
    it "moves a field to a nested location" do
      subject.move_field(:name, to: [ :user, :first_name ])
      expect(subject.build[:user][:first_name]).to eq("John")
      expect(subject.build).not_to have_key(:name)
    end

    it "creates intermediate keys if they don't exist" do
      subject.move_field(:name, to: [ :new_section, :deep, :id ])
      expect(subject.build[:new_section][:deep][:id]).to eq("John")
    end

    it "does nothing if field does not exist" do
      subject.move_field(:missing, to: [ :somewhere ])
      expect(subject.build).not_to have_key(:somewhere)
    end

    it "moves a nested field to root (flattening)" do
      subject.move_field([:meta, :id], to: :legacy_id)
      expect(subject.build[:legacy_id]).to eq(123)
      expect(subject.build[:meta]).not_to have_key(:id)
    end

    it "moves a deeply nested field to another nested location" do
      subject.move_field([:meta, :tracking, :code], to: [:shipping, :tracking_code])
      expect(subject.build[:shipping][:tracking_code]).to eq("XYZ")
      expect(subject.build[:meta][:tracking]).not_to have_key(:code)
    end
  end
end
