module Hackney
  module Notification
    class SendManualPrecompiledLetter < BaseManualGateway
      def execute(user_id: nil, payment_ref: nil, template_id:, unique_reference:, letter_pdf:)
        send_letter_response =
          notification_gateway.send_precompiled_letter(
            unique_reference: unique_reference,
            letter_pdf: letter_pdf
          )

        # FIXME: this must be in a background job => UH is unreliable
        # TODO: create job to accept exact same args as add_action_diary_usecase

        const = template_id.split(' ').join('_').upcase
        action_code = "Hackney::Tenancy::ActionCodes::#{const}".constantize
        tenancy_ref = leasehold_gateway.new.map_tenancy_ref_to_payment_ref(payment_ref: payment_ref).dig(:tenancy_ref)
        add_action_diary_usecase.execute(
          user_id: user_id,
          tenancy_ref: tenancy_ref,
          action_code: action_code,
          comment: "Letter '#{unique_reference}' from '#{template_id}' letter was sent
          access it by visiting documents?payment_ref=#{payment_ref}"
        )

        send_letter_response
      end
    end
  end
end
