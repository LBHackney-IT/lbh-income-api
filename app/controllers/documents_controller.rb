class DocumentsController < ApplicationController
  def download
    doc_download = letter_use_case_factory.download.execute(id: params.fetch(:id))
    doc = doc_download[:document]

    if user_can_write_to_action_diary?

      tenancy_ref = get_tenancy_ref(doc)
      send_lba_action = {
        tenancy_ref: tenancy_ref,
        action_code: 'SLB',
        comment: 'LBA sent (SC)',
        username: params[:username]
      }

      add_action_to_action_diary(action: send_lba_action)
      update_document_status
    end
    send_file doc_download[:filepath], type: doc.mime_type, filename: letter_file_name(doc)
  end

  def review_failure
    render json: letter_use_case_factory.review_failure.execute(document_id: params.fetch(:id))
  end

  def index
    render json: letter_use_case_factory.get_all_documents.execute(
      payment_ref: params.fetch(:payment_ref, nil),
      page_number: params.fetch(:page_number, 1).to_i,
      documents_per_page: params.fetch(:documents_per_page, 20).to_i
    )
  end

  private

  def letter_file_name(doc)
    return 'letter.pdf' unless doc.metadata
    meta = JSON.parse(doc.metadata).symbolize_keys
    pay_ref = meta.dig(:payment_ref)
    letter_template = meta.dig(:template_id)
    pay_ref.to_s + '_' + letter_template.to_s + doc.extension
  end

  def get_tenancy_ref(doc)
    tenancy_finder = Hackney::Income::UniversalHousingLeaseholdGateway.new
    payment_ref = JSON.parse(doc.metadata)['payment_ref']
    result = tenancy_finder.get_tenancy_ref(payment_ref: payment_ref)
    result[:tenancy_ref]
  end

  def user_can_write_to_action_diary?
    document_status = Hackney::Cloud::Document.find(params[:id]).status
    params[:username].present? && document_status == 'uploaded' && params[:documents_view] != 'true'
  end

  def add_action_to_action_diary(action:)
    income_use_case_factory.add_action_diary.execute(action)
  end

  def update_document_status
    Hackney::Cloud::Document.find(params[:id]).update(status: 'downloaded')
  end
end
