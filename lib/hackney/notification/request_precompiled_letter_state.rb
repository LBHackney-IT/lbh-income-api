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
        document_store = Hackney::Cloud::Document
        doc = document_store.find_by!(uuid: message_id)
        doc.status = status
        doc.save!
      end
    end
  end
end
