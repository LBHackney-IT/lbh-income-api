module Hackney
  module Income
    class SqlLegalCasesGateway
      def get_tenancies_for_legal_process_for_patch(patch:)
        Hackney::UniversalHousing::Client.with_connection do |database|
          database.extension :identifier_mangling
          database.identifier_input_method = database.identifier_output_method = nil
          query = database[:MATenancyAgreement]

          query
            .left_join(:MAProperty, prop_ref: :prop_ref)
            .where(Sequel[:MAProperty][:arr_patch] => patch.upcase)
            .where(Sequel[:MATenancyAgreement][:tenure] => SECURE_TENURE_TYPE)
            .where(Sequel[:MATenancyAgreement][:terminated].cast(:integer) => 0)
            .where(Sequel[:MATenancyAgreement][:high_action] => LEGAL_STAGES)
            .select { Sequel[:MATenancyAgreement][:tag_ref].as(:tag_ref) }
            .map { |record| record[:tag_ref].strip }
        end
      end

      LEGAL_STAGES = %w[4RS 5RP 6RC 6RO 7RE].freeze
      SECURE_TENURE_TYPE = 'SEC'.freeze
    end
  end
end
