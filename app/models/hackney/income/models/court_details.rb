module Hackney
  module Income
    module Models
      class CourtDetails < ApplicationRecord
        validates_presence_of :agreement_id, :court_decision_date, :court_outcome, :balance_at_outcome_date
        belongs_to :agreement, -> { where agreement_type: :formal }, class_name: 'Hackney::Income::Models::Agreement'
      end
    end
  end
end
