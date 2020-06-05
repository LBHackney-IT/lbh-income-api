module Hackney
  module Income
    module Models
      class AgreementState < ApplicationRecord
        belongs_to :agreement, class_name: 'Hackney::Income::Models::Agreement'
      end
    end
  end
end
