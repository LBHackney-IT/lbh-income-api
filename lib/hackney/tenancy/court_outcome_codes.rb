module Hackney
  module Tenancy
    module CourtOutcomeCodes
      ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE = 'AGP'.freeze
      ADJOURNED_TO_NEXT_OPEN_DATE = 'AND'.freeze
      ADJOURNED_TO_ANOTHER_HEARING_DATE = 'AAH'.freeze
      ADJOURNED_FOR_DIRECTIONS_HEARING = 'ADH'.freeze
      ADJOURNED_ON_TERMS = 'ADT'.freeze

      OUTRIGHT_POSSESSION_FORTHWITH = 'OPF'.freeze
      OUTRIGHT_POSSESSION_WITH_DATE = 'OPD'.freeze

      SUSPENSION_ON_TERMS = 'SOT'.freeze
      STRUCK_OUT = 'STO'.freeze
      WITHDRAWN_ON_THE_DAY = 'WIT'.freeze

      STAY_OF_EXECUTION = 'SOE'.freeze
    end
  end
end
