require 'sidekiq-scheduler'

class LeaseholdSync
  include Sidekiq::Worker
  def perform
    puts '* LeaseholdSync Running *'
    use_case_factory = Hackney::Leasehold::UseCaseFactory.new
    retry_count = 0

    max_retries = 5
    delay = 1.minute

    begin
      use_case_factory.schedule_sync_actions.execute
    rescue Sequel::DatabaseConnectionError => e
      raise 'All retries are exhausted' if retry_count >= max_retries
      retry_count += 1
      delay *= retry_count
      puts "[#{Time.now}] Oh no, we failed on #{e.inspect}."

      puts "Retries left: #{max_retries - retry_count}"
      puts "Retrying in: #{delay} seconds"
      sleep delay *= retry_count
      retry
    end
  end
end
