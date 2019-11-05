module UseCases
  class UpdateDocumentS3Url
    UPLOADED_CLOUD_STATUS = :uploaded

    def execute(document_data:, document_model:)
      document_model.update!(url: document_data[:url], status: UPLOADED_CLOUD_STATUS)
    end
  end
end
