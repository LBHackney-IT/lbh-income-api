module Hackney
  module Cloud
    class Document < ApplicationRecord
      # the end status maps to https://docs.notifications.service.gov.uk/java.html#status-letter
      # Accepted    GOV.UK Notify has sent the letter to the provider to be printed.
      # Received    The provider has printed and dispatched the letter.
      enum status: { uploading: 0, uploaded: 1, received: 2, accepted: 3, 'validation-failed' => 4, downloaded: 5, queued: 6 }

      def failed?
        status == 'validation-failed'
      end

      def parsed_metadata
        JSON.parse(metadata).deep_symbolize_keys
      end

      def income_collection?
        parsed_metadata
          .dig(:template, :path)
          .include?(Hackney::PDF::GetTemplatesForUser::INCOME_COLLECTION_TEMPLATE_DIRECTORY_PATH)
      end

      def self.find_by_payment_ref(payment_ref)
        where("JSON_EXTRACT(metadata, '$.payment_ref') = ? AND status != 1", payment_ref).order(updated_at: :DESC)
      end
    end
  end
end
