module Hackney
  module Income
    module Models
      class CourtDetails < ApplicationRecord
        validates_presence_of :agreement_id
        belongs_to :agreement, class_name: 'Hackney::Income::Models::Agreement'
      end
    end
  end
end
