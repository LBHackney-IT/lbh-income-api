module Hackney
  module Cloud
    module Jobs
      class SaveToCloudJob < ApplicationJob
        UPLOADED_CLOUD_STATUS = :uploaded

        queue_as :cloud_storage

        def perform(bucket_name:, filename:, new_filename:, model_document:, uuid:)
          url = cloud_provider.upload(bucket_name: bucket_name,
                                      filename: filename,
                                      new_filename: new_filename)

          document(model_document, uuid).update(url: url, status: UPLOADED_CLOUD_STATUS)
        end

        def cloud_provider
          Rails.configuration.cloud_adapter
        end

        private

        def document(model_document, uuid)
          model_document.constantize.find_by(uuid: uuid)
        end
      end
    end
  end
end
