# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdjustmentSerializer, type: :serializer do
  subject(:serialized) { described_class.new(adjustment).serializable_hash }

  let(:order) { create(:order) }
  let(:adjustment) do
    create(
      :adjustment,
      order: order,
      label: 'Tax',
      amount: 5.00,
      eligible: true,
      created_at: Time.zone.parse('2024-01-01 10:00'),
      updated_at: Time.zone.parse('2024-01-02 11:00')
    )
  end

  it 'has the correct type' do
    expect(serialized.dig(:data, :type)).to eq(:adjustment)
  end

  it 'serializes id as a string' do
    expect(serialized.dig(:data, :id)).to eq(adjustment.id.to_s)
  end

  it 'serializes attributes correctly' do
    attrs = serialized.dig(:data, :attributes)

    expect(attrs[:label]).to eq('Tax')
    expect(attrs[:amount]).to eq(5.00)
    expect(attrs[:eligible]).to eq(true)
    expect(attrs[:display_amount]).to eq(adjustment.display_amount)
    expect(attrs[:created_at]).to eq adjustment.created_at
    expect(attrs[:updated_at]).to eq adjustment.updated_at
  end
end
