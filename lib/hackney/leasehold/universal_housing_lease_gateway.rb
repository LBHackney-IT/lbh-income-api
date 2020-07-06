module Hackney
  module Leasehold
    class UniversalHousingLeaseGateway
      def self.lease_in_arrears
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
    end
  end
end
