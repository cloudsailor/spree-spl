# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Cart, type: :model do
  let(:klass) do
    Class.new do
      include Spree::Cart
      include CartDecorator

      attr_accessor :order
    end
  end

  let(:instance) { klass.new }
  let(:order) { create(:order, public_metadata: public_metadata) }

  before { instance.order = order }

  describe '#order_spl? (private)' do
    context 'when metadata is empty' do
      let(:public_metadata) { {} }

      it 'returns false' do
        expect(instance.send(:order_spl?)).to eq(false)
      end
    end

    context 'when spl_no_card is missing' do
      let(:public_metadata) { { spl_card_active: true } }

      it 'returns false' do
        expect(instance.send(:order_spl?)).to eq(false)
      end
    end

    context 'when spl_card_active is missing' do
      let(:public_metadata) { { spl_no_card: '0123456789123' } }

      it 'returns false' do
        expect(instance.send(:order_spl?)).to eq(false)
      end
    end

    context 'when both keys exist as symbol keys' do
      let(:public_metadata) do
        {
          spl_no_card: '0123456789123',
          spl_card_active: true
        }
      end

      it 'returns the spl_card_active value' do
        expect(instance.send(:order_spl?)).to eq(true)
      end
    end

    context 'when both keys exist as string keys' do
      let(:public_metadata) do
        {
          'spl_no_card' => '0123456789123',
          'spl_card_active' => true
        }
      end

      it 'returns the spl_card_active value' do
        expect(instance.send(:order_spl?)).to eq(true)
      end
    end

    context 'when keys are mixed' do
      let(:public_metadata) do
        {
          'spl_no_card' => '0123456789123',
          spl_card_active: false
        }
      end

      it 'returns the spl_card_active value' do
        expect(instance.send(:order_spl?)).to eq(false)
      end
    end

    context 'when spl_card_active is false' do
      let(:public_metadata) do
        {
          spl_no_card: '0123456789123',
          spl_card_active: false
        }
      end

      it 'returns false' do
        expect(instance.send(:order_spl?)).to eq(false)
      end
    end

    context 'when spl_card_active is a truthy string' do
      let(:public_metadata) do
        {
          'spl_no_card' => '0123456789123',
          'spl_card_active' => 'true'
        }
      end

      it 'returns the raw value (string) as-is' do
        expect(instance.send(:order_spl?)).to eq('true')
      end
    end
  end
end
