module Hackney
  module Income
    module Domain
      class NotificationReceipt
        attr_accessor :body

        def initialize(body:)
          @body = body
        end

        def body_without_newlines
          @body&.squish
        end
      end
    end
  end
end
