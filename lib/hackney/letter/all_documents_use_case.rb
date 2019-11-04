module Hackney
  module Letter
    class AllDocumentsUseCase
      def initialize(cloud_storage:)
        @cloud_storage = cloud_storage
      end

      def execute(payment_ref: nil)
        @cloud_storage.all_documents(payment_ref: payment_ref)
                      .each do |doc|
          metadata = JSON.parse(doc.metadata).deep_symbolize_keys if doc.metadata
          metadata ||= {}
          metadata[:username] = doc.username

          doc.metadata = metadata.to_json
        end
      end
    end
  end
end
