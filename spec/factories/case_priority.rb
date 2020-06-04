FactoryBot.define do
  sequence :tenancy_ref do |n|
    Faker::Lorem.characters(number: 10) + n.to_s
  end

  factory :case_priority, class: Hackney::Income::Models::CasePriority do
    # association :case

    tenancy_ref
    balance { Faker::Commerce.price(range: 10..1000.0) }
    days_in_arrears { Faker::Number.between(from: 5, to: 1000) }
    active_agreement { false }
    is_paused_until { nil }

    trait :red do
      priority_band { 'red' }
    end
  end
end
