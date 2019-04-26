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

        tenancy_ref = leasehold_gateway.new.get_tenancy_ref(payment_ref: payment_ref).dig(:tenancy_ref)
        add_action_diary_usecase.execute(
          user_id: user_id,
          tenancy_ref: tenancy_ref,
          action_code: action_code(template_id: template_id),
          comment: "Letter '#{unique_reference}' from '#{template_id}' letter was sent
          access it by visiting documents?payment_ref=#{payment_ref}"
        )

        send_letter_response
      end

      private

      def action_code(template_id:)
        const_from_template_id = template_id.split(' ').join('_').upcase
        "Hackney::Tenancy::ActionCodes::#{const_from_template_id}".constantize
      end
    end
  end
end
