# frozen_string_literal: true

module Spl
  # Base service accumulating shared methods to DRY subclasses
  class BaseSplService
    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end
  end
end
