module Hackney
  module Income
    class UpdateAllAgreementState
      WorktrayItem = Hackney::Income::Models::CasePriority

      def initialize(update_agreement_state:)
        @update_agreement_state = update_agreement_state
      end

      def execute
        all_active_agreements =
          Hackney::Income::Models::Agreement.where('current_state =? OR current_state =?', 'live', 'breached')

        all_active_agreements.each do |agreement|
          current_balance = WorktrayItem.find_by(tenancy_ref: agreement.tenancy_ref).balance
          @update_agreement_state.execute(agreement: agreement, current_balance: current_balance)
        rescue StandardError => e
          puts "[#{Time.now}] Failed to update agreement state " \
               "for agreement: #{agreement.id} of tenancy: #{agreement.tenancy_ref}, with error: #{e.inspect}."
          Raven.capture_exception(e)
        end
      end
    end
  end
end
