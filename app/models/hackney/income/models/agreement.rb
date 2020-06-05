module Hackney
  module Income
    module Models
      class Agreement < ApplicationRecord
        has_one :agreement_state, class_name: 'Hackney::Income::Models::AgreementState'
        enum agreement_type: { informal: 0, formal: 1 }
        enum frequency: { weekly: 0, monthly: 1 }
      end
    end
  end
end
