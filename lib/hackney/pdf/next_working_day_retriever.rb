module Hackney
  module PDF
    class NextWorkingDayRetriever
      UnsuccessfulRetrievalError = Class.new(StandardError)
      API_URL = 'https://www.gov.uk/bank-holidays.json'.freeze
      DEFAULT_GROUP = 'england-and-wales'.freeze

      def execute
        bank_holidays = Rails.cache.fetch('Hackney/PDF/BankHolidays', expires_in: 1.day) do
          get_bank_holidays
        end

        get_next_working_day(bank_holidays).strftime('%d %B %Y')
      end

      def uri
        URI.parse(API_URL)
      end

      def get_bank_holidays
        response = Net::HTTP.get_response(uri)

        raise_error(response) unless response.is_a?(Net::HTTPOK)

        data = JSON.parse(response.body)

        return [] if data.empty?

        data.dig(DEFAULT_GROUP, 'events')&.pluck('date')
      end

      def raise_error(response)
        raise UnsuccessfulRetrievalError, "Retrieval Failed: #{response.message} (#{response.code || response.status})"
      end

      def get_next_working_day(bank_holidays)
        possible_date = Time.now + 1.day

        possible_date += 1.day while bank_holidays.include?(possible_date.strftime('%Y-%m-%d')) == true
        possible_date += 2.day if possible_date.saturday?
        possible_date += 1.day if possible_date.sunday?
        return possible_date if bank_holidays.empty?
        possible_date += 1.day while bank_holidays.include?(possible_date.strftime('%Y-%m-%d')) == true
        possible_date
      end
    end
  end
end
