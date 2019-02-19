module Hackney
  module Cloud
    class Storage
      HACKNEY_BUCKET_DOCS = 'hackney-docs'.freeze

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
                                        mime_type: Rack::Mime.mime_type(extension))

        if new_doc.errors.empty?
          url = cloud_provider.upload(HACKNEY_BUCKET_DOCS, filename, new_filename)
          new_doc.update(url: url)
        end

        { errors: new_doc.errors.full_messages }
      end

      def upload(bucket_name, filename, new_filename)
        @storage_adapter.upload(bucket_name, filename, new_filename)
      end

      private

      def cloud_provider
        Rails.configuration.cloud_adaptor
      end

      attr_reader :document_model
    end
  end
end
