module Hackney
  module CourtOutcomeHelper
    def human_readable_outcome(code)
      code_mapping = {
        'AGP' => 'Adjourned generally with permission to restore',
        'AND' => 'Adjourned to next open date',
        'AAH' => 'Adjourned to another hearing date',
        'ADH' => 'Adjourned for directions hearing',
        'ADT' => 'Adjourned on terms',
        'OPF' => 'Outright possession forthwith',
        'OPD' => 'Outright possession with date',
        'SOT' => 'Suspension on terms',
        'STO' => 'Struck out',
        'WIT' => 'Withdrawn on the day',
        'SOE' => 'Stay of execution'
      }

      code_mapping[code]
    end
  end
end
