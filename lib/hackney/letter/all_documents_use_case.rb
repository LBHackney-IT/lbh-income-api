module Hackney
  module Letter
    class AllDocumentsUseCase
      def initialize(cloud_storage:)
        @cloud_storage = cloud_storage
      end

      def execute(payment_ref: nil, page_number: 1, documents_per_page: 20)
        response = @cloud_storage.all_documents(
          payment_ref: payment_ref,
          page_number: page_number,
          documents_per_page: documents_per_page
        )

        response.documents.each do |doc|
          metadata = doc.parsed_metadata
          metadata[:username] = doc.username
          doc.metadata = metadata.to_json
        end

        response
      end
    end
  end
end
