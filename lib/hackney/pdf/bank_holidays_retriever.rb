module Hackney
  module PDF
    class BankHolidaysRetriever
      UnsuccessfulRetrievalError = Class.new(StandardError)
      API_URL = 'https://www.gov.uk/bank-holidays.json'
      DEFAULT_GROUP = 'england-and-wales'

      def execute
        make_request
        begin
          get_dates
        rescue
          return []
        end
      end

      def uri
        URI.parse(API_URL)
      end

      def make_request
        @response ||= Net::HTTP.get_response(uri)

        return raise_error unless @response.is_a?(Net::HTTPOK)
      end

      def get_dates
        @data ||= JSON.parse(@response.body)

        return [] if @data.empty?

        @data.dig(DEFAULT_GROUP, 'events')&.pluck('date')
      end

      def raise_error
        raise UnsuccessfulRetrievalError, "Retrieval Failed: #{@response.message} (#{@response.code || @response.status}) #{@response.body}"
      end
    end
  end
end
