module Hackney
  module Income
    module Domain
      class NotificationReceipt
        attr_accessor :body

        def body_without_newlines
          @body&.squish
        end
      end
    end
  end
end
