Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  config.cache_store = :memory_store

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.x.gov_notify.api_key = ENV.fetch('GOV_NOTIFY_API_KEY')

  logger           = ActiveSupport::Logger.new(STDOUT)
  logger.formatter = config.log_formatter
  config.logger    = ActiveSupport::TaggedLogging.new(logger)

  # Configure the Cloud storage service
  encryption_client = Hackney::Cloud::EncryptionClient.new(config_for('cloud_storage')['customer_managed_key']).create
  download_client = Hackney::Cloud::DownloadEncryptionClient.new(config_for('cloud_storage')['download_key']).create

  config.cloud_adapter = Hackney::Cloud::Adapter::AwsS3.new(encryption_client)
  config.download_adapter = Hackney::Cloud::Adapter::AwsS3.new(download_client)
end
