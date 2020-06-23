module Hackney
  module ServiceCharge
    class UniversalHousingPrioritisationGateway
      def priorities_for_lease(payment_ref)
        logger("> About to connect to UH for #{tenancy_ref}")
        overall_start_time = Time.zone.now

        response = Hackney::UniversalHousing::Client.with_connection do |database|
          logger(">> About to start getting Criteria (overall time taken so far): #{Time.zone.now - overall_start_time}ms")
          criteria_start_time = Time.zone.now

          criteria = Hackney::Income::UniversalHousingCriteria.for_lease(database, payment_ref)

          logger(">> Time taken for Criteria from UH: #{Time.zone.now - criteria_start_time}ms")

          { criteria: criteria }
        end

        logger("> Overall time taken loading from UH: #{Time.zone.now - overall_start_time}ms")

        response
      end

      private

      def logger(message)
        Rails.logger.tagged('UH-PrioritisationGateway') do
          Rails.logger.info(message)
        end
      end
    end
  end
end
