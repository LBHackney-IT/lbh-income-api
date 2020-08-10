module Hackney
  module Income
    module Models
      class CourtCase < ApplicationRecord
        validates_presence_of :tenancy_ref
        validates_presence_of :terms, if: :adjourned?
        validates_presence_of :disrepair_counter_claim, if: :adjourned?
        has_many :agreements, -> { where agreement_type: :formal }, class_name: 'Hackney::Income::Models::Agreement'

        def adjourned?
          court_outcome&.start_with?('A')
        end
      end
    end
  end
end
