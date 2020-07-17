module Hackney
  module Leasehold
    class UniversalHousingGateway
      def fetch(tenancy_ref)
        logger("> About to connect to UH for #{tenancy_ref}")
        overall_start_time = Time.zone.now

        response = Hackney::UniversalHousing::Client.with_connection do |database|
          logger(">> About to start getting Criteria (overall time taken so far): #{Time.zone.now - overall_start_time}ms")
          criteria_start_time = Time.zone.now

          task_attributes = Hackney::Leasehold::UniversalHousingAttributes.for_lease(database, tenancy_ref)

          logger(">> Time taken for Criteria from UH: #{Time.zone.now - criteria_start_time}ms")

          task_attributes
        end

        logger("> Overall time taken loading from UH: #{Time.zone.now - overall_start_time}ms")

        response
      end

      def tenancy_refs_in_arrears
        Hackney::UniversalHousing::Client.with_connection do |database|
          database.extension :identifier_mangling
          database.identifier_input_method = database.identifier_output_method = nil

          query = database[:tenagree]

          query
            .select(:tag_ref)
            .exclude(tenure: FREEHOLD_TENURE_TYPE)
            .where { cur_bal > 0 }
            .where(rentgrp_ref: LEASE_RENT_GROUP)
            .where(terminated: 0)
            .where(agr_type: MASTER_ACCOUNT_TYPE)
            .map { |item| item[:tag_ref].strip }
        end
      end

      LEASE_RENT_GROUP = 'LSC'.freeze
      FREEHOLD_TENURE_TYPE = 'FRE'.freeze
      MASTER_ACCOUNT_TYPE = 'M'.freeze

      private

      def logger(message)
        Rails.logger.tagged('UH-PrioritisationGateway') do
          Rails.logger.info(message)
        end
      end
    end
  end
end
