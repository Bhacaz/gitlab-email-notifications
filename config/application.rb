# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GitlabEmailNotifications
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.session_store :cookie_store, expire_after: 20.years

    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { database: { writing: :queue } }
    SolidApm.connects_to = { database: { writing: :solid_apm } }
    config.action_mailbox.ingress = :mailgun
    config.active_storage.service = :db

    # Load configuration from environment variables.
    # In development/test, set these in a .env file (see .env.example).
    # In production, inject them via Docker environment or your hosting platform.
    config.x.gitlab.application_id  = ENV.fetch('GITLAB__APP_ID', nil)
    config.x.gitlab.secret_id       = ENV.fetch('GITLAB__APP_SECRET', nil)
    config.x.gitlab.callback_url    = ENV.fetch('GITLAB__CALLBACK_URL', nil)
    config.x.email_domain           = ENV.fetch('EMAIL_DOMAIN', nil)
    config.x.admin.username         = ENV.fetch('ADMIN__USERNAME', nil)
    config.x.admin.password         = ENV.fetch('ADMIN__PASSWORD', nil)
  end
end
