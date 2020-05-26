module Hackney
  module PDF
    class BankHolidaysRetriever
      UnsuccessfulRetrievalError = Class.new(StandardError)
      API_URL = 'https://www.gov.uk/bank-holidays.json'.freeze
      DEFAULT_GROUP = 'england-and-wales'.freeze

      def execute
        Rails.cache.fetch('Hackney/PDF/BankHolidays', expires_in: 1.day) do
          get_dates
        end
      end

      def uri
        URI.parse(API_URL)
      end

      def get_dates
        response = Net::HTTP.get_response(uri)

        raise_error(response) unless response.is_a?(Net::HTTPOK)

        data = JSON.parse(response.body)

        return [] if data.empty?

        data.dig(DEFAULT_GROUP, 'events')&.pluck('date')
      end

      def raise_error(response)
        raise UnsuccessfulRetrievalError, "Retrieval Failed: #{response.message} (#{response.code || response.status})"
      end
    end
  end
end
