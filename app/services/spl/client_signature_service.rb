# frozen_string_literal: true

require 'digest'

module Spl
  class ClientSignatureService
    def initialize(date)
      @date = date
    end

    def call
      generate_signature
    end

    private

    def generate_signature
      data = "#{ENV['SPL_API_TOKEN']}#{ENV['SPL_SIGNATURE_SEED']}#{@date}"
      Rails.logger.debug data.inspect
      Digest::SHA256.hexdigest(data)
    end
  end
end
