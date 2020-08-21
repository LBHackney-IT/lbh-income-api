module Hackney
  module Income
    module Models
      class AgreementLegacyMigration < ApplicationRecord
        validates_presence_of :legacy_id, :agreement_id
        belongs_to :agreement, class_name: 'Hackney::Income::Models::Agreement'
      end
    end
  end
end
