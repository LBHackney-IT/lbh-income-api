module Hackney
  module Letter
    class ReviewFailure
      def initialize(cloud_storage:)
        @cloud_storage = cloud_storage
      end

      def execute(document_id:)
        document = @cloud_storage.document_model.find(document_id)
        @cloud_storage.update_document_status(document: document, status: :failure_reviewed)
      end
    end
  end
end
