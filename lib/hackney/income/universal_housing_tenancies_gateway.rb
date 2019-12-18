module Hackney
  module Income
    class UniversalHousingTenanciesGateway
      def tenancies_in_arrears
        Hackney::UniversalHousing::Client.with_connection do |database|
          database.extension :identifier_mangling
          database.identifier_input_method = database.identifier_output_method = nil

          database[:tenagree]
            .select(:tag_ref)
            .where { cur_bal > 0 }
            .where(tenure: SECURE_TENURE_TYPE)
            .where(terminated: 0)
            .where(agr_type: MASTER_ACCOUNT_TYPE)
            .map { |item| item[:tag_ref].strip }
        end
      end

      SECURE_TENURE_TYPE = 'SEC'.freeze
      MASTER_ACCOUNT_TYPE = 'M'.freeze
    end
  end
end
