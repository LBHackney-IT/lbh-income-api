module Hackney
  module Notification
    class RequestPrecompiledLetterState < BaseManualGateway
      def execute(document:)
        response =
          notification_gateway.precompiled_letter_state(
            message_id: document.ext_message_id
          )

        document_store.update_document_status(document: document, status: response[:status])

        if document.income_collection? && document.failed?
          related_case = case_priority_store.by_payment_ref(document.parsed_metadata[:payment_ref])

          add_action_diary_and_pause_case_usecase.execute(
            tenancy_ref: related_case.tenancy_ref,
            action_code: Hackney::Tenancy::ActionCodes::LETTER_FAILED_VALIDATION_CODE,
            comment: "Letter '#{document.uuid}' from '#{document.parsed_metadata.dig(:template, :id)}' letter " \
              'failed to send. Please check Gov Notify for more detail, once the issue is resolved update the ' \
              "document by visiting documents?payment_ref=#{document.parsed_metadata.dig(:payment_ref)}"
          )
        end

        response
      end
    end
  end
end
