FactoryBot.define do
  factory :court_case, class: Hackney::Income::Models::CourtCase do
    tenancy_ref { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
    court_date { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
    court_outcome { Faker::ChuckNorris.fact }
    balance_on_court_outcome_date { Faker::Commerce.price(range: 10...100) }
    strike_out_date { Faker::Date.forward(days: 365) }
    created_by { Faker::Name.name }
  end
end
