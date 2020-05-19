module Hackney
  module PDF
    class BankHolidaysRetriever
      UnsuccessfulRetrievalError = Class.new(StandardError)
      API_URL = 'https://www.gov.uk/bank-holidays.json'
      DEFAULT_GROUP = 'england-and-wales'

      def uri
        URI.parse(API_URL)
      end

      def execute
        @response ||= Net::HTTP.get_response(uri)

        return raise_error unless @response.is_a?(Net::HTTPOK)

        @data = JSON.parse(@response.body)

        @data.dig(DEFAULT_GROUP, 'events')&.pluck('date')
      end




#       def self.dates
#         new.dates(DEFAULT_GROUP)
#       end

#       def data
#         return raise_error unless response.is_a?(Net::HTTPOK)

#         @data ||= JSON.parse(response.body)
#       end

#       def dates(group)
#         return if data.empty?

#         data.dig(group, 'events')&.pluck('date')
#       end

#       private

#       def response
#         @response ||= Net::HTTP.get_response(uri)
#       end

      def raise_error
        raise UnsuccessfulRetrievalError, "Retrieval Failed: #{@response.message} (#{@response.code || @response.status}) #{@response.body}"
      end
    end
  end
end
