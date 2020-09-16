FactoryBot.define do
  factory :eviction_date, class: Hackney::Income::Models::EvictionDate do
    tenancy_ref { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
    eviction_date { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
  end
end
