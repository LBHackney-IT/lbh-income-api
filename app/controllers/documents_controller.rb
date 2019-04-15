class DocumentsController < ApplicationController
  def download
    doc_download = letter_use_case_factory.download.execute(id: params.fetch(:id))
    doc = doc_download[:document]

    send_file doc_download[:filepath], type: doc.mime_type, filename: letter_file_name(doc)
  end

  def index
    render json: letter_use_case_factory.get_all_documents.execute
  end

  private

  def letter_file_name(doc)
    return 'letter.pdf' unless doc.metadata
    meta = JSON.parse(doc.metadata).symbolize_keys
    pay_ref = meta.dig(:payment_ref)
    letter_template = meta.dig(:template_id)
    pay_ref.to_s + '_' + letter_template.to_s + doc.extension
  end
end
