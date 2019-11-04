require "#{Rails.root}/lib/hackney/service_charge/exceptions/service_charge_exception"

class LettersController < ApplicationController
  def get_templates
    render json: pdf_use_case_factory.get_templates.execute
  end

  def create
    letter_data = UseCases::ViewLetter.new.execute
    _uuid = UseCases::SaveToCache.new(cache: Rails.cache).execute(data: letter_data)

    # we'll have to include some data from the previous
    # use cases to get this response right
    json = pdf_use_case_factory.get_preview.execute(
      payment_ref: params.fetch(:payment_ref),
      template_id: params.fetch(:template_id)
    )

    render json: json
  rescue Hackney::Income::TenancyNotFoundError
    head(404)
  end

  def send_letter
    # 1. Pop from cache x
    # 2. Generate PDF x
    # 3. Create Document Model x
    # 4. Upload to S3 x
    # 5. Update document with S3 URL x
    # 6. Send to notify (via job)
    # 7. Write to action diary (via job on success of 6)

    pop_letter_from_cache = UseCases::PopLetterFromCache.new(cache: Rails.cache)
    letter = pop_letter_from_cache.execute(uuid: params.fetch(:uuid))

    generate_pdf = UseCases::GeneratePdf.new
    pdf = generate_pdf.execute(uuid: params.fetch(:uuid), letter_html: letter[:preview])

    create_document_model = UseCases::CreateDocumentModel.new(Hackney::Cloud::Document)
    document_model = create_document_model.execute(letter_html: letter[:preview], uuid: params.fetch(:uuid), filename: params.fetch(:uuid), metadata: {
      user_id: params.fetch(:user_id),
      payment_ref: letter[:case][:payment_ref],
      template: letter[:template]
    })

    save_letter = UseCases::SaveLetterToCloud.new(Rails.configuration.cloud_adapter)
    document_data = save_letter.execute(
      uuid: params.fetch(:uuid),
      bucket_name: Rails.application.config_for('cloud_storage')['bucket_docs'],
      pdf: pdf
    )

    update_document_s3_url = UseCases::UpdateDocumentS3Url.new
    update_model = update_document_s3_url.execute(document_model: document_model, document_data: document_data)

    # find_letter = UseCases::FindLetterInCloud.new(Rails.configuration.cloud_adapter)
    # pdf = find_letter.execute(document_data: document_data)

    # send_letter = UseCases::SendLetter.new(notify_gateway: nil)
    # send_letter.execute(letter: pdf)

    # write_to_action_diary = UseCases::RecordLetterSent(action_diary_gateway: nil)
    # write_to_action_diary.execute(letter: letter)

    # this calls the ProcessLetter use case, which also sends the letter
    income_use_case_factory.send_letter.execute(
      uuid: params.fetch(:uuid),
      user_id: params.fetch(:user_id),
      payment_ref: letter[:case][:payment_ref],
      template_name: letter[:template],
      letter_content: letter[:preview]
    )
  end
end
