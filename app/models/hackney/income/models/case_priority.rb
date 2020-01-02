module Hackney
  module Income
    module Models
      class CasePriority < ApplicationRecord
        enum classification: {
          no_action: 0, send_letter_two: 1, send_letter_one: 2, send_first_SMS: 3, send_NOSP: 4,
          apply_for_court_date: 6, send_court_warning_letter: 7, send_court_agreement_breach_letter: 8
        }

        validates :case_id, presence: true, uniqueness: true

        before_validation :create_case_with_tenancy_ref

        belongs_to :case, class_name: 'Hackney::Income::Models::Case', optional: true

        def tenancy_ref
          # TODO: please do not use tenancy_ref has been moved to Hackney::Income::Models::Case'
          read_attribute(:tenancy_ref)
        end

        def create_case_with_tenancy_ref
          self.case_id ||= Hackney::Income::Models::Case.find_or_create_by(tenancy_ref: tenancy_ref).id
        end

        def paused?
          is_paused_until ? is_paused_until.future? : false
        end

        def self.not_paused
          where('is_paused_until < ? OR is_paused_until is null', Date.today)
        end

        def self.criteria_for_green_in_arrears
          where(priority_band: 'green')
            .where('days_in_arrears >= ?', 5)
            .where('balance >= ?', 10.00)
            .where(active_agreement: false)
            .not_paused
        end
      end
    end
  end
end
