module Hackney
  module Notification
    class SendManualPrecompiledLetter < BaseManualGateway
      def execute(username: nil, payment_ref: nil, template_id:, unique_reference:, letter_pdf:, tenancy_ref: nil)
        send_letter_response =
          notification_gateway.send_precompiled_letter(
            unique_reference: unique_reference,
            letter_pdf: letter_pdf
          )

        # FIXME: this must be in a background job => UH is unreliable
        # TODO: create job to accept exact same args as add_action_diary_and_pause_case_usecase

        tenancy_ref ||= leasehold_gateway.get_tenancy_ref(payment_ref: payment_ref).dig(:tenancy_ref)

        ad_code = action_code(template_id: template_id)
        Rails.logger.info "writing action diary code #{ad_code} from template_id: #{template_id} for Letter '#{unique_reference}'"

        add_action_diary_and_pause_case_usecase.execute(
          username: username,
          tenancy_ref: tenancy_ref,
          action_code: ad_code,
          comment: "Letter '#{unique_reference}' from '#{template_id}' letter " \
            "was sent access it by visiting documents?payment_ref=#{payment_ref}"
        )

        send_letter_response
      end

      private

      def action_code(template_id:)
        const_from_template_id = template_id.to_s.split(' ').join('_').upcase
        "Hackney::Tenancy::ActionCodes::#{const_from_template_id}".constantize
      end
    end
  end
end
