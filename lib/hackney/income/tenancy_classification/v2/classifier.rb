module Hackney
  module Income
    module TenancyClassification
      module V2
        class Classifier
          include Helpers

          def initialize(case_priority, criteria, documents, use_ma_data = false)
            @criteria = criteria
            @case_priority = case_priority
            @documents = documents
            @use_ma_data = use_ma_data
          end

          def execute
            rulesets = [
              Rulesets::ApplyForOutrightPossessionWarrant,
              Rulesets::ReviewFailedLetter,
              Rulesets::SendSMS,
              Rulesets::SendLetterOne,
              Rulesets::SendLetterTwo,
              Rulesets::UpdateCourtOutcomeAction,
              Rulesets::CourtBreachVisit,
              Rulesets::SendNOSP,
              Rulesets::CourtBreachNoPayment,
              Rulesets::SendInformalAgreementBreachLetter,
              Rulesets::InformalBreachedAfterLetter,
              Rulesets::AddressCourtAgreementBreach, # TODO(AO): Possible missing test for this classification
              Rulesets::SendCourtWarningLetter,
              Rulesets::ApplyForCourtDate,
              Rulesets::CheckData
            ]

            actions = rulesets.map { |ruleset| ruleset.new(@case_priority, @criteria, @documents, @use_ma_data).execute }

            actions.compact!

            actions << :no_action if actions.none?

            if actions.length > 1
              if actions == %i[send_first_SMS send_letter_one]
                actions = %i[send_letter_one]
              else
                Rails.logger.error(
                  'CLASSIFIER: Multiple recommended actions from V2' \
              "Actions: #{actions} " \
              "tenancy_ref: #{@criteria.tenancy_ref}"
                )
              end
            end

            validate_wanted_action(actions.first)

            actions.first
          end

          private

          def validate_wanted_action(wanted_action)
            return false if Hackney::Income::Models::CasePriority.classifications.key?(wanted_action)
            raise ArgumentError, "Tried to classify a case as #{wanted_action}, but this is not on the list of valid classifications."
          end

          def active_agreement_court_outcomes
            [
              Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS,
              Hackney::Tenancy::CourtOutcomeCodes::POSTPONED_POSSESSION,
              Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION
            ]
          end
        end
      end
    end
  end
end
