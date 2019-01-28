require_relative 'boot'
require_relative 'feature_toggle'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    include FeatureToggle

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.eager_load_paths << Rails.root.join('lib')

    config.active_job.queue_adapter = :delayed_job

    config.x.run_tenancy_sync_jobs = feature_toggle('ENABLE_TENANCY_SYNC')

    config.x.gov_notify.send_live = feature_toggle('SEND_LIVE_COMMUNICATIONS')
    config.x.gov_notify.test_phone_number = ENV.fetch('TEST_PHONE_NUMBER', '123456789')
    config.x.gov_notify.sms_sender_id = ENV.fetch('GOV_NOTIFY_SENDER_ID', SecureRandom.uuid)
    config.x.gov_notify.test_email_address = ENV.fetch('TEST_EMAIL_ADDRESS', 'test@example.com')

    config.x.green_in_arrears.sms_template_id = ENV.fetch('GREEN_IN_ARREARS_SMS_TEMPLATE_ID', 'b168529b-2d87-467e-ab51-7e50aeae9c2e')
    config.x.green_in_arrears.email_template_id = ENV.fetch('GREEN_IN_ARREARS_EMAIL_TEMPLATE_ID', 'd36cb99b-7e7e-4859-a1d0-d8083d0f0391')
  end
end
