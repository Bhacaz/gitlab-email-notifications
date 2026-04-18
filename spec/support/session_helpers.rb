# frozen_string_literal: true

# Request spec helper for signing in as a specific user by writing the encrypted
# session cookie directly — no HTTP round-trip, no test-only endpoints.
#
# Rails CookieStore encrypts the session hash as JSON with aes-256-gcm, keyed
# from the app's secret_key_base using the "authenticated encrypted cookie" salt,
# and stamped with purpose "cookie._session_id".
#
# Usage (in a request spec):
#   before { sign_in_as(user) }
module SessionHelpers
  def sign_in_as(user)
    key_len = ActiveSupport::MessageEncryptor.key_len('aes-256-gcm')
    secret = Rails.application.key_generator.generate_key('authenticated encrypted cookie', key_len)
    encryptor = ActiveSupport::MessageEncryptor.new(
      secret, cipher: 'aes-256-gcm',
              serializer: ActiveSupport::MessageEncryptor::NullSerializer
    )
    cookies[:_session_id] = encryptor.encrypt_and_sign(
      { 'session_id' => SecureRandom.hex, 'user_id' => user.id }.to_json,
      purpose: 'cookie._session_id'
    )
  end
end
