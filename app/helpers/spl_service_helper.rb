module SplServiceHelper
  def send_request(url, body)
    Spl::SendRequestService.new(url, body).call
  end
end