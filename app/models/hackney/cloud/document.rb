module Hackney
  module Cloud
    class Document < ApplicationRecord
      # the end status maps to https://docs.notifications.service.gov.uk/java.html#status-letter
      # Accepted    GOV.UK Notify has sent the letter to the provider to be printed.
      # Received    The provider has printed and dispatched the letter.
      enum status: { uploading: 0, uploaded: 1, received: 2, accepted: 3, 'validation-failed' => 4 }

      def failed?
        status == 'validation-failed'
      end
    end
  end
end
