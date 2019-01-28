module Hackney
  module Income
    class ScheduleGreenInArrearsMessage
      def initialize(matching_criteria_gateway:, background_job_gateway:)
        @matching_criteria_gateway = matching_criteria_gateway
        @background_job_gateway = background_job_gateway
      end

      def execute
        tenancies_list = @matching_criteria_gateway.criteria_for_green_in_arrears
        Rails.logger.info("About to schedule #{tenancies_list.length} green in arrears msg jobs")
        tenancies_list.each do |tenancy|
          @background_job_gateway.schedule_send_green_in_arrears_msg(case_id: tenancy.case_id)
        end
      end
    end
  end
end
