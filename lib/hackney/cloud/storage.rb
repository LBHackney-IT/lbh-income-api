module Hackney
  module Cloud
    class Storage
      HACKNEY_BUCKET_DOCS = Rails.application.config_for('cloud_storage')['bucket_docs']
      UPLOADING_CLOUD_STATUS = :uploading

      def initialize(storage_adapter, document_model)
        @storage_adapter = storage_adapter
        @document_model = document_model
      end

      def save(filename)
        raise "No such file: #{filename}" unless File.exist?(filename)

        uuid = SecureRandom.uuid
        extension = File.extname(filename)
        new_filename = "#{uuid}#{extension}"

        new_doc = document_model.create(filename: filename,
                                        uuid: uuid,
                                        extension: extension,
                                        mime_type: Rack::Mime.mime_type(extension),
                                        status: UPLOADING_CLOUD_STATUS)

        if new_doc.errors.empty?
          Hackney::Cloud::Jobs::SaveToCloudJob.perform_later(bucket_name: HACKNEY_BUCKET_DOCS,
                                                             filename: filename,
                                                             new_filename: new_filename,
                                                             model_document: document_model.name,
                                                             uuid: uuid)
        end

        { errors: new_doc.errors.full_messages }
      end

      def upload(bucket_name, filename, new_filename)
        @storage_adapter.upload(bucket_name, filename, new_filename)
      end

      private

      attr_reader :document_model
    end
  end
end
