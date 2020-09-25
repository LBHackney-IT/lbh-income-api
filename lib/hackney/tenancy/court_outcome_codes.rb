module Hackney
  module Tenancy
    module CourtOutcomeCodes
      # These are the legacy outcome codes from UH, should not be used other than migrating old agreement data from UH

      OUTRIGHT_POSSESSION_WITH_DATE = 'OPD'.freeze
      OUTRIGHT_POSSESSION_FORTHWITH = 'OPF'.freeze

      ADJOURNED_GENERALLY = 'AGE'.freeze
      ADJOURNED_ON_TERMS = 'ADT'.freeze
      ADJOURNED_ON_TERMS_SECONDARY = 'AOT'.freeze

      POSTPONED_POSSESSION = 'PPO'.freeze

      SUSPENDED_POSSESSION = 'SUP'.freeze
    end
  end
end
