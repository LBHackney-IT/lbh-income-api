require 'hackney/income/universal_housing_leasehold_gateway.rb'

module UseCases
  class GenerateAndStoreLetter
    def execute(payment_ref:, tenancy_ref:, template_id:, user:)
      pdf_use_case_factory = Hackney::PDF::UseCaseFactory.new
      letter_use_case_factory = Hackney::Letter::UseCaseFactory.new

      income_collection_templates = %w[income_collection_letter_1 income_collection_letter_2]
      agreement_templates = %w[informal_agreement_confirmation_letter]

      if template_id.in?(income_collection_templates)
        letter_data = pdf_use_case_factory.get_income_preview.execute(
          tenancy_ref: tenancy_ref,
          template_id: template_id,
          user: user
        )
      elsif template_id.in?(agreement_templates)
        agreement = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).select(&:active?).last
        letter_data = pdf_use_case_factory.get_income_preview.execute(
          tenancy_ref: tenancy_ref,
          template_id: template_id,
          user: user,
          agreement: agreement
        )
      else
        letter_data = pdf_use_case_factory.get_preview.execute(
          payment_ref: payment_ref,
          template_id: template_id,
          user: user
        )
      end

      return letter_data if letter_data[:errors].present?

      uuid = letter_data[:uuid]
      filename = "#{uuid}.pdf"

      generate_pdf = UseCases::GeneratePdf.new
      pdf = generate_pdf.execute(uuid: uuid, letter_html: letter_data[:preview])

      document_model = letter_use_case_factory.create_document_model.execute(
        letter_html: letter_data[:preview],
        uuid: uuid,
        filename: filename,
        metadata: {
          username: user.name,
          email: user.email,
          payment_ref: letter_data[:case][:payment_ref],
          template: letter_data[:template]
        }
      )

      cloud_response = letter_use_case_factory.save_letter_to_cloud.execute(
        filename: filename,
        bucket_name: Rails.application.config_for('cloud_storage')['bucket_docs'],
        pdf: pdf
      )

      update_document_s3_url = UseCases::UpdateDocumentS3Url.new
      update_document_s3_url.execute(document_model: document_model, document_data: cloud_response)

      letter_data[:document_id] = document_model.id

      letter_data
    end
  end
end
