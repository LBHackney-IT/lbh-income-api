module Hackney
  module Income
    class UpdateAllAgreementState
      def initialize(update_agreement_state:)
        @update_agreement_state = update_agreement_state
      end

      def execute
        all_active_agreements =
          Hackney::Income::Models::Agreement.where('current_state =? OR current_state =?', 'live', 'breached')

        all_active_agreements.each do |agreement|
          @update_agreement_state.execute(agreement: agreement)
        rescue StandardError => e
          puts "[#{Time.now}] Failed to update agreement state " \
               "for agreement: #{agreement.id} of tenancy: #{agreement.tenancy_ref}, with error: #{e.inspect}."
          Raven.capture_exception(e)
        end
      end
    end
  end
end
