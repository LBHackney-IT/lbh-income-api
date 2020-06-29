module Hackney
  module PDF
    class NextWorkingDayRetriever
      UnsuccessfulRetrievalError = Class.new(StandardError)
      API_URL = 'https://www.gov.uk/bank-holidays.json'.freeze
      DEFAULT_GROUP = 'england-and-wales'.freeze

      def execute
        get_next_working_day.strftime('%d %B %Y')
      end

      private

      def get_next_working_day
        possible_date = Time.now + 1.day
        possible_date += 1.day while bank_holiday?(possible_date) || weekend?(possible_date)

        possible_date
      end

      def weekend?(date)
        date.saturday? || date.sunday?
      end

      def bank_holiday?(date)
        bank_holidays.include?(date.strftime('%Y-%m-%d'))
      end

      def bank_holidays
        @bank_holidays ||= Rails.cache.fetch('Hackney/PDF/BankHolidays', expires_in: 1.day) do
          get_bank_holidays
        end
      end

      def get_bank_holidays
        response = Net::HTTP.get_response(uri)

        raise_error(response) unless response.is_a?(Net::HTTPOK)

        data = JSON.parse(response.body)

        return [] if data.empty?

        data.dig(DEFAULT_GROUP, 'events')&.pluck('date')
      end

      def uri
        URI.parse(API_URL)
      end

      def raise_error(response)
        raise UnsuccessfulRetrievalError, "Retrieval Failed: #{response.message} (#{response.code || response.status})"
      end
    end
  end
end
