module Hackney
  module Income
    module Models
      class CourtCase < ApplicationRecord
        validates_presence_of :tenancy_ref, :court_decision_date, :court_outcome, :balance_at_outcome_date, :strike_out_date, :created_by
        has_many :agreements, -> { where agreement_type: :formal }, class_name: 'Hackney::Income::Models::Agreement'
      end
    end
  end
end
