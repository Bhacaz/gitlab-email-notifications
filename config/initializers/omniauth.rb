# frozen_string_literal: true

return if ENV['SECRET_KEY_BASE_DUMMY']

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :gitlab,
           Rails.application.config.x.gitlab.application_id,
           Rails.application.config.x.gitlab.secret_id,
           scope: 'read_user',
           redirect_uri: Rails.application.config.x.gitlab.callback_url,
           callback_path: '/oauth/gitlab/callback'
end

OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.silence_get_warning = true
