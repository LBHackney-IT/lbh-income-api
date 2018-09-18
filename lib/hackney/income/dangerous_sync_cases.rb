module Hackney
  module Income
    class DangerousSyncCases
      def initialize(uh_tenancies_gateway:, background_job_gateway:)
        @uh_tenancies_gateway = uh_tenancies_gateway
        @background_job_gateway = background_job_gateway
      end

      def execute
        @uh_tenancies_gateway.tenancies_in_arrears.each do |tenancy_ref|
          @background_job_gateway.schedule_case_priority_sync(tenancy_ref: tenancy_ref)
        end
      end
    end
  end
end
