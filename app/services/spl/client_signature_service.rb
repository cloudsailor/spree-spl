# frozen_string_literal: true

require 'digest'

module Spl
  class ClientSignatureService
    def initialize(date, spl_api_token, spl_signature_seed)
      @date = date
      @spl_api_token = spl_api_token
      @spl_signature_seed = spl_signature_seed
    end

    def call
      generate_signature
    end

    private

    def generate_signature
      data = "#{@spl_api_token}#{@spl_signature_seed}#{@date}"
      Rails.logger.debug data.inspect
      Digest::SHA256.hexdigest(data)
    end
  end
end
