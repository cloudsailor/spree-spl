# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BooleanHelper, type: :helper do
  describe '#cast_boolean' do
    subject(:cast) { helper.cast_boolean(value) }

    context 'when value is truthy' do
      [
        true,
        'true',
        'TRUE',
        '1',
        1
      ].each do |truthy_value|
        context "with value #{truthy_value.inspect}" do
          let(:value) { truthy_value }

          it 'returns true' do
            expect(cast).to eq(true)
          end
        end
      end
    end

    context 'when value is falsy' do
      [
        false,
        'false',
        'FALSE',
        '0',
        0
      ].each do |falsy_value|
        context "with value #{falsy_value.inspect}" do
          let(:value) { falsy_value }

          it 'returns false' do
            expect(cast).to eq(false)
          end
        end
      end
    end
  end
end
