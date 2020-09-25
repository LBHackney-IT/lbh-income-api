module Hackney
  module Income
    class CreateEvictionAndSync
      def initialize(add_action_diary_and_sync_case:, create_eviction:)
        @create_eviction = create_eviction
        @add_action_diary_and_sync_case = add_action_diary_and_sync_case
      end

      def execute(eviction_params:, username: nil)
        params = {
          tenancy_ref: eviction_params[:tenancy_ref],
          date: eviction_params[:date]
        }
        eviction = @create_eviction.execute(eviction_params: params)

        if username
          @add_action_diary_and_sync_case.execute(
            tenancy_ref: eviction_params[:tenancy_ref],
            action_code: Hackney::Tenancy::ActionCodes::EVICTION_DATE_SET,
            comment: "Eviction date set to #{eviction_params[:date]}",
            username: username
          )
        end

        eviction
      end
    end
  end
end
