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

      private

      def cloud_storage
        Hackney::Cloud::Storage.new(Rails.configuration.cloud_adapter, Hackney::Cloud::Document)
      end
    end
  end
end
