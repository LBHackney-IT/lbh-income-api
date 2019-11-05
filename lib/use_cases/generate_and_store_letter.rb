require 'hackney/income/universal_housing_leasehold_gateway.rb'

module UseCases
  class GenerateAndStoreLetter
    def execute(payment_ref:, template_id:, user_id:)
      pdf_use_case_factory = Hackney::PDF::UseCaseFactory.new
      letter_use_case_factory = Hackney::Letter::UseCaseFactory.new

      json = pdf_use_case_factory.get_preview.execute(
        payment_ref: payment_ref,
        template_id: template_id
      )

      return json if json[:errors].present?

      uuid = json[:uuid]
      filename = "#{uuid}.pdf"

      generate_pdf = UseCases::GeneratePdf.new
      pdf = generate_pdf.execute(uuid: uuid, letter_html: json[:preview])

      document_model = letter_use_case_factory.create_document_model.execute(
        letter_html: json[:preview],
        uuid: uuid,
        filename: filename,
        metadata: {
          user_id: user_id,
          payment_ref: json[:case][:payment_ref],
          template: json[:template]
        }
      )

      document_data = letter_use_case_factory.save_letter_to_cloud.execute(
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
