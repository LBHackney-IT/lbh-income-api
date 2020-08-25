module Hackney
  module Income
    class MigrateUhAgreement
      def initialize(
        view_agreements:,
        view_court_cases:,
        create_informal_agreement:,
        create_formal_agreement:,
        create_agreement_migration:
      )
        @view_agreements = view_agreements
        @view_court_cases = view_court_cases
        @create_informal_agreement = create_informal_agreement
        @create_formal_agreement = create_formal_agreement
        @create_agreement_migration = create_agreement_migration
      end

      def migrate(tenancy_ref:)
        uh_agreements = Hackney::UniversalHousing::Client.with_connection do |database|
          Hackney::Income::UniversalHousingAgreementGateway.for_tenancy(
            database,
            tenancy_ref
          )
        end

        return unless uh_agreements.any?

        ma_agreements = @view_agreements.execute(tenancy_ref: tenancy_ref)

        return unless ma_agreements.empty?

        court_cases = @view_court_cases.execute(tenancy_ref: tenancy_ref)

        if court_cases.any?
          formal_agreement = uh_agreements.pop

          uh_agreements.each do |agreement|
            migrate_informal_agreement(agreement, tenancy_ref)
          end

          migrate_formal_agreement(court_cases, formal_agreement, tenancy_ref)

        else
          uh_agreements.each do |agreement|
            migrate_informal_agreement(agreement, tenancy_ref)
          end
        end
      end

      private

      def migrate_formal_agreement(court_cases, formal_agreement, tenancy_ref)
        new_agreement = create_formal_agreement(tenancy_ref, formal_agreement, court_cases.last.id)

        add_agreement_migration(formal_agreement[:uh_id], new_agreement.id)
      end

      def migrate_informal_agreement(agreement, tenancy_ref)
        new_agreement = create_informal_agreement(tenancy_ref, agreement)

        add_agreement_migration(agreement[:uh_id], new_agreement.id)
      end

      def create_formal_agreement(tenancy_ref, agreement, court_case_id)
        @create_formal_agreement.execute(
          new_agreement_params: generate_params(tenancy_ref, agreement, :formal, court_case_id)
        )
      end

      def create_informal_agreement(tenancy_ref, agreement)
        @create_informal_agreement.execute(
          new_agreement_params: generate_params(tenancy_ref, agreement, :informal)
        )
      end

      def add_agreement_migration(legacy_id, agreement_id)
        @create_agreement_migration.execute(agreement_migration_params: {
          legacy_id: legacy_id,
          agreement_id: agreement_id
        })
      end

      def generate_params(tenancy_ref, agreement, type, court_case_id = nil)
        {
          tenancy_ref: tenancy_ref,
          agreement_type: type,
          starting_balance: agreement[:starting_balance],
          amount: agreement[:amount],
          start_date: agreement[:start_date],
          frequency: get_frequency(agreement[:frequency]),
          created_by: 'Managed Arrears migration from UH',
          notes: agreement[:comment],
          court_case_id: court_case_id
        }
      end

      def get_frequency(uh_frequency)
        frequency_mapping = [
          {
            uh_frequency: 0, # Monthly
            ma_frequency: 1
          }, {
            uh_frequency: 1, # Weekly
            ma_frequency: 0
          }, {
            uh_frequency: 2, # 2 Weekly
            ma_frequency: 2
          }, {
            uh_frequency: 4, # 4 Weekly
            ma_frequency: 3
          }
        ]

        frequency_mapping.find { |f| f[:uh_frequency] == uh_frequency }[:ma_frequency]
      end
    end
  end
end
