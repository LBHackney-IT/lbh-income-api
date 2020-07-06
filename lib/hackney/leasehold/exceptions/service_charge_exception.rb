module Hackney
  module Leasehold
    module Exceptions
      class LeaseholdException < StandardError
        attr_reader :response
        def initialize(response)
          super
          @response = response
        end

        def to_s
          "[Service Charge API error: Received #{response&.code} response] #{super}"
        end
      end
    end
  end
end
