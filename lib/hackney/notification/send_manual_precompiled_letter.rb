module Hackney
  module Notification
    class SendManualPrecompiledLetter < BaseManualGateway
      def execute(user_id: nil, payment_ref: nil, template_id:, unique_reference:, letter_pdf:)
        gateway = Hackney::Income::UniversalHousingLeaseholdGateway.new

        send_letter_response =
          notification_gateway.send_precompiled_letter(
            unique_reference: unique_reference,
            letter_pdf: letter_pdf
          )

        # FIXME:
        # Codes for letters as follows:
        # Letter 1 in arrears FH (code LF1)
        # Letter 2 in arrears FH (code LF2)
        # Letter 1 in arrears LH (code LL1)
        # Letter 2 in arrears LH (code LL2)
        # Letter 1 in arrears SO (code LS1)
        # Letter 2 in arrears SO (code LS2)
        # const = 'Letter 1 in arrears FH'.split(' ').join('_').upcase

        # TODO: this really must be in a background job => UH is unreliable
        # TODO: create job to accept exact same args as add_action_diary_usecase

        const = template_id.split(' ').join('_').upcase
        action_code = "Hackney::Tenancy::ActionCodes::#{const}".constantize
        # TODO: add action diary event if payment_ref

        tenancy_ref = gateway.map_tenancy_ref_to_payment_ref(payment_ref: payment_ref).dig(:tenancy_ref)

        add_action_diary_usecase.execute(
          user_id: user_id,
          tenancy_ref: tenancy_ref,
          action_code: action_code,
          comment: "'#{unique_reference}' letter was sent"
        )

        send_letter_response
      end
    end
  end
end
