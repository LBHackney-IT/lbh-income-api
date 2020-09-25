module Hackney
  module CourtOutcomeHelper
    def human_readable_outcome(code)
      code_mapping = {
        Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE => 'Adjourned generally with permission to restore',
        Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_TO_NEXT_OPEN_DATE => 'Adjourned to next open date',
        Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_TO_ANOTHER_HEARING_DATE => 'Adjourned to another hearing date',
        Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING => 'Adjourned for directions hearing',
        Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS => 'Adjourned on terms',
        Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH => 'Outright possession forthwith',
        Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE => 'Outright possession with date',
        Hackney::Tenancy::CourtOutcomeCodes::SUSPENSION_ON_TERMS => 'Suspension on terms',
        Hackney::Tenancy::CourtOutcomeCodes::STRUCK_OUT => 'Struck out',
        Hackney::Tenancy::CourtOutcomeCodes::WITHDRAWN_ON_THE_DAY => 'Withdrawn on the day',
        Hackney::Tenancy::CourtOutcomeCodes::STAY_OF_EXECUTION => 'Stay of execution/Re-entry'
      }

      code_mapping[code]
    end
  end
end
