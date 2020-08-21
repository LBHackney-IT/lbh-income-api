module Hackney
  module Income
    class CreateAgreementMigration
      def execute(agreement_migration_params:)
        params = {
          legacy_id: agreement_migration_params[:legacy_id],
          agreement_id: agreement_migration_params[:agreement_id]
        }

        Hackney::Income::Models::AgreementLegacyMigration.create!(params)
      end
    end
  end
end
