module Spl
  class BaseSplService
    def initialize;end
    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end
  end
end