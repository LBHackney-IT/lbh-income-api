module Hackney
  module Leasehold
    class ScheduleSyncActions
      def initialize(universal_housing_gateway:, background_job_gateway:)
        @universal_housing_gateway = universal_housing_gateway
        @background_job_gateway = background_job_gateway
        @stored_actions_model = Hackney::IncomeCollection::Action
      end

      def execute
        Rails.logger.info('preparing to sync tenancies_in_arrears ')

        tenancy_refs = @universal_housing_gateway.tenancy_refs_in_arrears
        found_actions = @stored_actions_model.all

        Rails.logger.info("About to schedule #{tenancy_refs.length} leasehold action sync jobs")
        tenancy_refs.each do |tenancy_ref|
          @background_job_gateway.schedule_case_priority_sync(tenancy_ref: tenancy_ref)
        end

        delete_actions_not_syncable(actions: found_actions, tenancy_refs: tenancy_refs)
      end

      private

      def delete_actions_not_syncable(actions:, tenancy_refs:)
        Rails.logger.info('Deleting case_priorities that are not to be synced')
        action_refs_not_synced = actions.pluck(:tenancy_ref) - tenancy_refs
        @stored_actions_model.where(tenancy_ref: action_refs_not_synced).destroy_all if action_refs_not_synced.any?
      end
    end
  end
end
