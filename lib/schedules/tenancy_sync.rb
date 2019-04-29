require 'sidekiq-scheduler'

class TenancySync
  include Sidekiq::Worker
  def perform
    puts '* TenancySync Running *'
    use_case_factory = Hackney::Income::UseCaseFactory.new
    retry_count = 0

    max_retries = 5
    delay = 1.minute

    begin
      use_case_factory.schedule_sync_cases.execute
    rescue Sequel::DatabaseConnectionError => err
      raise 'All retries are exhausted' if retry_count >= max_retries
      retry_count += 1
      delay *= retry_count
      puts "[#{Time.now}] Oh no, we failed on #{err.inspect}."

      puts "Retries left: #{max_retries - retry_count}"
      puts "Retrying in: #{delay} seconds"
      sleep delay *= retry_count
      retry
    end
  end
end
