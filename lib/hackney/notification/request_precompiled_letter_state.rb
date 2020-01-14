module Hackney
  module Notification
    class RequestPrecompiledLetterState < BaseManualGateway
      def execute(document:)
        response =
          notification_gateway.precompiled_letter_state(
            message_id: document.ext_message_id
          )

        update_document(document: document, status: response[:status])

        if document.income_collection? && document.failed?
          related_case = case_priority_store.by_payment_ref(document.parsed_metadata[:payment_ref])

          add_action_diary_usecase.execute(
            tenancy_ref: related_case.tenancy_ref,
            action_code: Hackney::Tenancy::ActionCodes::LETTER_FAILED_VALIDATION_CODE,
            comment: "Letter '#{document.uuid}' from '#{document.parsed_metadata.dig(:template, :id)}' letter " \
              'failed to send. Please check Gov Notify for more detail, once the issue is resolved update the ' \
              "document by visiting documents?payment_ref=#{document.parsed_metadata.dig(:payment_ref)}"
          )
        end

        response
      end

      def update_document(document:, status:)
        Rails.logger.info "Document ext_message_id #{document.ext_message_id} found with status #{status}"
        document.status = status
        document.save!

        message = "Document has been set to #{status} - id: #{document.id}, uuid: #{document.uuid}"
        Rails.logger.info message

        evt = Raven::Event.new(message: message)
        Raven.send_event(evt) if document.failed?
      end
    end
  end
end
