module Hackney
  module Cloud
    class Document < ApplicationRecord
      enum status: { uploading: 0, uploaded: 1, received: 2, accepted: 3, 'validation-failed' => 4 }

      def failed?
        status == 'validation-failed'
      end
    end
  end
end
