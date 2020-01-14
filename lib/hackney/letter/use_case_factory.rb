module Hackney
  module Letter
    class UseCaseFactory
      def download
        Hackney::Letter::DownloadUseCase.new(
          cloud_storage
        )
      end

      def get_all_documents
        Hackney::Letter::AllDocumentsUseCase.new(
          cloud_storage: cloud_storage
        )
      end

      def create_document_model
        UseCases::CreateDocumentModel.new(
          Hackney::Cloud::Document
        )
      end

      def review_failure
        Hackney::Letter::ReviewFailure.new(
          cloud_storage: cloud_storage
        )
      end

      def save_letter_to_cloud
        UseCases::SaveLetterToCloud.new(
          Rails.configuration.cloud_adapter
        )
      end

      private

      def cloud_storage
        Hackney::Cloud::Storage.new(Rails.configuration.cloud_adapter, Hackney::Cloud::Document)
      end
    end
  end
end
