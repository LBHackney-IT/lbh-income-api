module Hackney
  module Income
    class MigrateUhAgreement
      MigrateUhAgreementError = Class.new(StandardError)

      def initialize(
        view_agreements:,
        view_court_cases:,
        create_agreement:,
        create_agreement_migration:
      )
        @view_agreements = view_agreements
        @view_court_cases = view_court_cases
        @create_agreement = create_agreement
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
            migrate_informal_agreement(agreement, tenancy_ref, true)
          end

          migrate_formal_agreement(court_cases, formal_agreement, tenancy_ref)

        else
          last_agreement = uh_agreements.pop

          uh_agreements.each do |agreement|
            migrate_informal_agreement(agreement, tenancy_ref, true)
          end

          migrate_informal_agreement(last_agreement, tenancy_ref, false)
        end
      end

      private

      def migrate_formal_agreement(court_cases, formal_agreement, tenancy_ref)
        agreement_params, state_params = generate_agreement_and_state_params(
          tenancy_ref,
          formal_agreement,
          :formal,
          court_cases.last.id
        )

        new_agreement = @create_agreement.create_agreement(
          agreement_params, state_params
        )

        add_agreement_migration(formal_agreement[:uh_id], new_agreement.id)
      end

      def migrate_informal_agreement(agreement, tenancy_ref, cancel_if_live)
        agreement_params, state_params = generate_agreement_and_state_params(tenancy_ref, agreement, :informal)

        state_params[:agreement_state] = :cancelled if cancel_if_live && state_params[:agreement_state] == :live

        new_agreement = @create_agreement.create_agreement(
          agreement_params, state_params
        )

        add_agreement_migration(agreement[:uh_id], new_agreement.id)
      end

      def add_agreement_migration(legacy_id, agreement_id)
        @create_agreement_migration.execute(agreement_migration_params: {
          legacy_id: legacy_id,
          agreement_id: agreement_id
        })
      end

      def generate_agreement_and_state_params(tenancy_ref, agreement, type, court_case_id = nil)
        agreement_frequency = get_frequency(agreement[:frequency])

        agreement_state = get_state(agreement[:status])

        raise MigrateUhAgreementError, "Can not migrate live agreement with unsupported frequency, #{tenancy_ref}" if can_not_migrate(agreement_frequency, agreement_state)

        agreement_notes = get_note(agreement, agreement_frequency)

        agreement_params = {
          tenancy_ref: tenancy_ref,
          agreement_type: type,
          starting_balance: agreement[:starting_balance],
          amount: agreement[:amount],
          start_date: agreement[:start_date],
          frequency: agreement_frequency[:ma_frequency],
          created_by: 'Managed Arrears migration from UH',
          notes: agreement_notes,
          court_case_id: court_case_id
        }

        state_params = {
          starting_balance: agreement[:starting_balance],
          expected_balance: agreement[:last_check_expected_balance],
          checked_balance: agreement[:last_check_balance],
          description: 'Managed Arrears migration from UH',
          agreement_state: agreement_state
        }

        [agreement_params, state_params]
      end

      def can_not_migrate(agreement_frequency, agreement_state)
        agreement_frequency[:ma_frequency] == 4 && agreement_state == :live
      end

      def get_note(agreement, agreement_frequency)
        if agreement_frequency[:ma_frequency] == 4
          "Frequency no longer supported, original frequency was '#{agreement_frequency[:description]}'. #{agreement[:comment]}"
        else
          agreement[:comment]
        end
      end

      def get_frequency(uh_frequency)
        frequency_mapping = [
          {
            description: 'Monthly',
            uh_frequency: 0,
            ma_frequency: 1
          }, {
            description: 'Weekly',
            uh_frequency: 1,
            ma_frequency: 0
          }, {
            description: '2 Weekly',
            uh_frequency: 2,
            ma_frequency: 2
          }, {
            description: '4 Weekly',
            uh_frequency: 4,
            ma_frequency: 3
          }, {
            description: '3 Monthly',
            uh_frequency: 5,
            ma_frequency: 4
          }, {
            description: '6 Monthly',
            uh_frequency: 6,
            ma_frequency: 4
          }, {
            description: 'Annually',
            uh_frequency: 7,
            ma_frequency: 4
          }, {
            description: 'Daily',
            uh_frequency: 8,
            ma_frequency: 4
          }, {
            description: 'Irregular',
            uh_frequency: 9,
            ma_frequency: 4
          }, {
            description: 'Quarterly',
            uh_frequency: 'Q',
            ma_frequency: 4
          }
        ]

        frequency_mapping.find { |f| f[:uh_frequency] == uh_frequency }
      end

      def get_state(uh_state)
        state_mapping = [
          {
            uh_state: 100, # First Check
            ma_state: :live
          }, {
            uh_state: 200, # Live
            ma_state: :live
          }, {
            uh_state: 299, # Suspect
            ma_state: :live
          }, {
            uh_state: 300, # Breached
            ma_state: :breached
          }, {
            uh_state: 400, # Suspended
            ma_state: :cancelled
          }, {
            uh_state: 500, # Cancelled
            ma_state: :cancelled
          }, {
            uh_state: 600, # Complete
            ma_state: :completed
          }
        ]
        state_mapping.find { |f| f[:uh_state] == uh_state.to_i }[:ma_state]
      end
    end
  end
end
