module Hackney
  module Cloud
    class Storage
      attr_reader :document_model

      HACKNEY_BUCKET_DOCS = Rails.application.config_for('cloud_storage')['bucket_docs']
      UPLOADING_CLOUD_STATUS = :uploading

      def initialize(storage_adapter, document_model)
        @storage_adapter = storage_adapter
        @document_model = document_model
      end

      def save(letter_html:, uuid:, filename:, metadata:)
        extension = File.extname(filename)

        new_doc = document_model.create(
          filename: filename,
          uuid: uuid,
          extension: extension,
          mime_type: Rack::Mime.mime_type(extension),
          status: UPLOADING_CLOUD_STATUS,
          metadata: metadata.to_json,
          email: metadata[:email],
          username: metadata[:username]
        )

        if new_doc.errors.empty?
          Hackney::Income::Jobs::SaveAndSendLetterJob.perform_later(
            bucket_name: HACKNEY_BUCKET_DOCS,
            letter_html: letter_html,
            filename: filename,
            document_id: new_doc.id
          )
        end

        { errors: new_doc.errors.full_messages }
      end

      def read_document(id)
        document = document_model.find_by!(id: id)
        response = @storage_adapter.download(bucket_name: HACKNEY_BUCKET_DOCS, filename: document.uuid + document.extension)

        { filepath: response.path, document: document }
      end

      def all_documents(payment_ref: nil)
        if payment_ref.present?
          document_model.by_payment_ref(payment_ref).exclude_uploaded.order(created_at: :DESC)
        else
          document_model.exclude_uploaded.order(created_at: :DESC)
        end
      end

      def documents_to_update_status(time:)
        document_model.where('updated_at >= ?', time).exclude_uploaded
                      .where.not(status: %i[nil validation-failed received])
      end

      def upload(bucket_name, content, filename)
        if content.is_a? StringIO
          sio = Tempfile.open(filename, 'tmp/')
          sio.binmode

          sio.write content.read
          sio.rewind
          content = sio
        end

        @storage_adapter.upload(bucket_name: bucket_name, content: content, filename: filename)
      end

      def update_document_status(document:, status:)
        raise "Invalid document status: #{status}" unless document_model.statuses.include?(status)

        Rails.logger.info "Document ext_message_id #{document.ext_message_id} found with status #{status}"
        document.status = status
        document.save!

        message = "Document has been set to #{document.status} - id: #{document.id}, uuid: #{document.uuid}"
        Rails.logger.info message

        evt = Raven::Event.new(message: message)
        Raven.send_event(evt) if document.failed?
        document
      end
    end
  end
end
