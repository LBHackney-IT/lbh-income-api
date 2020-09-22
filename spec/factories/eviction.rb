FactoryBot.define do
  factory :eviction, class: Hackney::Income::Models::Eviction do
    tenancy_ref { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
    date { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
  end
end
