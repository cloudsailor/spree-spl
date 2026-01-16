# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::ErrorPayloadParser do
  describe '.parse' do
    subject(:parse) { described_class.parse(message) }

    context 'when message is a ruby-hash-like string' do
      let(:message) do
        %({"errorCode" => "TEMPORARY_BLOCKED", "validationMessages" => nil, "fieldValidationMessages" => nil, "response" => nil, "msg" => "Temporarily blocked (too much attempts)"})
      end

      it 'parses into a hash with string keys and values' do
        expect(parse).to eq(
          'errorCode' => 'TEMPORARY_BLOCKED',
          'validationMessages' => nil,
          'fieldValidationMessages' => nil,
          'response' => nil,
          'msg' => 'Temporarily blocked (too much attempts)'
        )
      end
    end

    context 'when message is not wrapped in braces' do
      let(:message) { %("errorCode" => "TEMPORARY_BLOCKED") }

      it 'returns nil' do
        expect(parse).to be_nil
      end
    end

    context 'when message is blank' do
      let(:message) { '   ' }

      it 'returns nil' do
        expect(parse).to be_nil
      end
    end

    context 'when message contains escaped quotes and backslashes' do
      let(:message) do
        %({"msg" => "He said \\"hi\\"", "path" => "C:\\\\Temp\\\\file"})
      end

      it 'unescapes values correctly' do
        expect(parse).to eq(
          'msg' => %(He said "hi"),
          'path' => %q(C:\Temp\file)
        )
      end
    end

    context 'when message contains nil values' do
      let(:message) { %({"response" => nil}) }

      it 'parses nil correctly' do
        expect(parse).to eq(
          'response' => nil
        )
      end
    end

    context 'when message includes unquoted values' do
      let(:message) { %({"errorCode" => 123, "msg" => "ok"}) }

      it 'keeps unquoted values as strings (best-effort parsing)' do
        expect(parse).to eq(
          'errorCode' => '123',
          'msg' => 'ok'
        )
      end
    end

    context 'when message is malformed' do
      let(:message) { %({this is not => valid,) }

      it 'returns nil (does not raise)' do
        expect(parse).to be_nil
      end
    end
  end
end
