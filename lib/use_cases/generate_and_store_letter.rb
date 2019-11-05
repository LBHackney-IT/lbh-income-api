require 'hackney/income/universal_housing_leasehold_gateway.rb'

module UseCases
  class GenerateAndStoreLetter
    def execute(payment_ref:, template_id:, user_id:)
      pdf_use_case_factory = Hackney::PDF::UseCaseFactory.new

      json = pdf_use_case_factory.get_preview.execute(
        payment_ref: payment_ref,
        template_id: template_id,
        user_id: user_id
      )

      return json if json[:errors].present?

      uuid = json[:uuid]
      filename = "#{uuid}.pdf"

      pop_letter_from_cache = UseCases::PopLetterFromCache.new(cache: Rails.cache)
      letter = pop_letter_from_cache.execute(uuid: uuid)

      generate_pdf = UseCases::GeneratePdf.new
      pdf = generate_pdf.execute(uuid: uuid, letter_html: letter[:preview])

      create_document_model = UseCases::CreateDocumentModel.new(Hackney::Cloud::Document)
      document_model = create_document_model.execute(
        letter_html: letter[:preview],
        uuid: uuid,
        filename: filename,
        metadata: {
          user_id: user_id,
          payment_ref: letter[:case][:payment_ref],
          template: letter[:template]
        }
      )

      save_letter = UseCases::SaveLetterToCloud.new(Rails.configuration.cloud_adapter)
      document_data = save_letter.execute(
        filename: filename,
        bucket_name: Rails.application.config_for('cloud_storage')['bucket_docs'],
        pdf: pdf
      )

      update_document_s3_url = UseCases::UpdateDocumentS3Url.new
      update_document_s3_url.execute(document_model: document_model, document_data: document_data)

      json[:document_id] = document_model.id

      json
    end
  end
end
