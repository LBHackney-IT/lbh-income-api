class Hackney::Income::Jobs::RequestPrecompiledLetterStateJob < ApplicationJob
  queue_as :default

  def perform(document_id:)
    Rails.logger.info("Starting RequestPrecompiledLetterStateJob for document_id #{document_id}")

    document = Hackney::Cloud::Document.find(document_id)
    income_use_case_factory.request_precompiled_letter_state.execute(
      message_id: document.ext_message_id
    )
  end
end
