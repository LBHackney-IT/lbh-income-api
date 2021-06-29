source 'https://rubygems.org'

# security patch pins min versions
gem 'aws-sdk-s3'
gem 'loofah', '>= 2.2.3'
gem 'rack', '>= 2.0.6'

ruby '2.7.1'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.2'
# Use sqlite3 as the database for Active Record

# Use Puma as the app server
gem 'puma', '~> 3.12'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'
gem 'faker'

gem 'httparty'
gem 'mysql2', '~> 0.5.2'
gem 'sequel'
gem 'tiny_tds'
gem 'uk_postcode'

gem 'daemons'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'notifications-ruby-client'
gem 'pdfkit'
gem 'phonelib'
gem 'redis-rails'
gem 'rswag-api'
gem 'rswag-ui'
gem 'sentry-raven'
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'wkhtmltopdf-binary'

group :test do
  gem 'pdf-reader'
  gem 'rspec-sidekiq'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'brakeman', '~> 4.3', '>= 4.3.1'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot'
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
  gem 'pry'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'shoulda-matchers', '~> 4.0'
  gem 'timecop'
  gem 'webmock'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'rubocop', '~> 0.74.0', require: false
  gem 'rubocop-faker'
  gem 'rubocop-rspec', '~> 1.31.0'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'simplecov', require: false
end

group :staging, :production do
  gem 'newrelic_rpm'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
