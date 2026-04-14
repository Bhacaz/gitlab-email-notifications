# frozen_string_literal: true

module Middleware
  class AdminBasicAuth
    ADMIN_PATH_PREFIX = '/admin'

    def initialize(app)
      @app = app
      @username = Rails.application.config.x.admin.username
      @password = Rails.application.config.x.admin.password

      return if ENV['SECRET_KEY_BASE_DUMMY']
      raise 'Admin credentials not set.' if @username.blank? || @password.blank?
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.path.start_with?(ADMIN_PATH_PREFIX)
        auth = Rack::Auth::Basic.new(@app, 'Admin Area') do |u, p|
          ActiveSupport::SecurityUtils.secure_compare(u, @username.to_s) &
            ActiveSupport::SecurityUtils.secure_compare(p, @password.to_s)
        end
        auth.call(env)
      else
        @app.call(env)
      end
    end
  end
end
