# frozen_string_literal: true

require 'openssl'

#
# webhook signature validator
#
class WebhookSignature
  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def initialize(secret:, http_x_hub_signature:, payload_body:)
    @secret = secret
    @http_x_hub_signature = http_x_hub_signature
    @signature = 'sha1=' +
                 OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, payload_body)
  end

  def valid?
    return true unless @secret
    return false unless @http_x_hub_signature

    Rack::Utils.secure_compare(@signature, @http_x_hub_signature)
  end

  def invalid?
    !valid?
  end
end
