module Hackney
  module Income
    module Models
      class CourtCase < ApplicationRecord
        validates_presence_of :tenancy_ref
        has_many :agreements, -> { where agreement_type: :formal }, class_name: 'Hackney::Income::Models::Agreement'
      end
    end
  end
end
