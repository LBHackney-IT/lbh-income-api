module Hackney
  module Income
    class UniversalHousingTenanciesGateway
      def tenancies_in_arrears
        Hackney::UniversalHousing::Client.with_connection do |database|
          database.extension :identifier_mangling
          database.identifier_input_method = database.identifier_output_method = nil

          query = database[:tenagree]

          query
            .where { Sequel[:tenagree][:cur_bal] > 0 }
            .where(Sequel[:tenagree][:tenure] => SECURE_TENURE_TYPE)
            .where(Sequel[:tenagree][:terminated].cast(:integer) => 0)
            .select { Sequel[:tenagree][:tag_ref].as(:tag_ref) }
            .map { |record| record[:tag_ref].strip }
        end
      end

      SECURE_TENURE_TYPE = 'SEC'.freeze
    end
  end
end
