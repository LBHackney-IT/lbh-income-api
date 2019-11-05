module UseCases
  class CreateDocumentModel
    UPLOADING_CLOUD_STATUS = :uploading

    def initialize(document_model)
      @document_model = document_model
    end

    def execute(letter_html:, uuid:, filename:, metadata:)
      extension = File.extname(filename)

      @document_model.create(
        filename: filename,
        uuid: uuid,
        extension: extension,
        mime_type: Rack::Mime.mime_type(extension),
        status: UPLOADING_CLOUD_STATUS,
        metadata: metadata.to_json
      )
    end
  end
end
