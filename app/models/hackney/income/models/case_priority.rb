module Hackney
  module Income
    module Models
      class CasePriority < ApplicationRecord
        enum classification: {
          no_action: 0, send_letter_two: 1, send_letter_one: 2, send_first_SMS: 3, send_NOSP: 4,
          apply_for_court_date: 6, send_court_warning_letter: 7, update_court_outcome_action: 8,
          send_court_agreement_breach_letter: 9, send_informal_agreement_breach_letter: 10,
          court_breach_visit: 11, court_breach_no_payment: 12, review_failed_letter: 13,
          apply_for_outright_possession_warrant: 14, informal_breached_after_letter: 15
        }

        validates :case_id, presence: true, uniqueness: true

        before_validation :create_case_with_tenancy_ref

        belongs_to :case, class_name: 'Hackney::Income::Models::Case', optional: true

        scope :by_payment_ref, ->(payment_ref) { where(payment_ref: payment_ref) }

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

        def nosp
          @nosp ||= Hackney::Domain::Nosp.new(served_date: nosp_served_date)
        end

        def self.not_paused
          where('is_paused_until <= ? OR is_paused_until IS NULL', Time.zone.now.beginning_of_day)
        end
      end
    end
  end
end
