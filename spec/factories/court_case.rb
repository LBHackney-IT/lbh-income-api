FactoryBot.define do
  factory :court_case, class: Hackney::Income::Models::CourtCase do
    tenancy_ref { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
    court_date { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
    balance_on_court_outcome_date { Faker::Commerce.price(range: 10...100) }
    strike_out_date { Faker::Date.forward(days: 365) }
    court_outcome do
      [
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_NEXT_OPEN_DATE,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_ANOTHER_HEARING_DATE,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::STRUCK_OUT,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::WITHDRAWN_ON_THE_DAY,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::STAY_OF_EXECUTION,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_ON_TERMS,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
        Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
      ].sample
    end
    terms { [true, false].sample if adjourned? }
    disrepair_counter_claim { [true, false].sample if adjourned? }
  end
end
