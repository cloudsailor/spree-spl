# frozen_string_literal: true

module SplServiceHelper
  def send_request(url, body)
    Spl::SendRequestService.new(url, body).call
  end

  # Refreshes user private token to keep possible
  # using customer oriented endpoints
  # @param [user: Spree::User]
  def refresh_user_token(user)
    return if user.private_metadata.nil?
    return if user.private_metadata['spl_refresh_token'].nil?

    response = Spl::OauthTokenService.refresh_token(user.private_metadata['spl_refresh_token'])

    user.update!(private_metadata: { spl_access_token: response['access_token'],
                                     spl_refresh_token: response['refresh_token'] })
  end

  def token_refresh_needed(response_body, retry_counter, user)
    token_expired?(response_body['errorCode']) && retry_counter < 1 && refresh_user_token(user)
  end
end
