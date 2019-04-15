module Hackney
  module Notification
    class RequestPrecompiledLetterState < BaseManualGateway
      def execute(message_id:)
        response =
          notification_gateway.precompiled_letter_state(
            message_id: message_id
          )

        update_document(message_id: message_id, status: response[:status])
        response
      end

      def update_document(message_id:, status:)
        store = Hackney::Cloud::Document
        doc = store.find_by!(uuid: message_id)
        doc.status = status

        Raven.send_event("Document has failed - id: #{doc.id}, uuid: #{doc.uuid}") if doc.failed?

        doc.save!
      end
    end
  end
end
