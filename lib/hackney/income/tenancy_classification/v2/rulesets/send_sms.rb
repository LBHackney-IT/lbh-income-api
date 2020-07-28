module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class SendSMS < BaseRuleset
            def execute
              return :send_first_SMS if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if @criteria.collectable_arrears.blank?
              return false if invalid_phone_number?
              return false if @criteria.courtdate.present?
              return false if @criteria.nosp.served?
              return false if @criteria.active_agreement?
              return false if breached_agreement? && !court_breach_agreement?
              return false if @criteria.collectable_arrears >= 10

              if @criteria.last_communication_action.present?
                return false if @criteria.last_communication_action.in?(blocking_communication_actions) &&
                                last_communication_newer_than?(7.days.ago)

                return false if !@criteria.last_communication_action.in?(blocking_communication_actions) &&
                                last_communication_newer_than?(3.months.ago)
              end

              @criteria.collectable_arrears >= 5 && no_court_date?
            end

            def blocking_communication_actions
              [
                Hackney::Tenancy::ActionCodes::AUTOMATED_SMS_ACTION_CODE,
                Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE,
                Hackney::Tenancy::ActionCodes::MANUAL_GREEN_SMS_ACTION_CODE,
                Hackney::Tenancy::ActionCodes::MANUAL_AMBER_SMS_ACTION_CODE,
                Hackney::Tenancy::ActionCodes::TEXT_MESSAGE_SENT
              ]
            end

            def invalid_phone_number?
              return true if @contact_numbers.empty?

              phone_number_valid = @contact_numbers.map do |phone_number|
                phone = Phonelib.parse(phone_number)
                phone.invalid? || phone.types.include?(:fixed_line)
              end

              return true if phone_number_valid.include?(true)
            end
          end
        end
      end
    end
  end
end
