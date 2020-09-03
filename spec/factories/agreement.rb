FactoryBot.define do
  factory :agreement, class: Hackney::Income::Models::Agreement do
    tenancy_ref { Faker::Lorem.characters(number: 5) }
    agreement_type { :informal }
    notes { Faker::ChuckNorris.fact }
    created_by { Faker::Name.name }
    starting_balance { Faker::Commerce.price(range: 100...1000) }
    frequency { [:weekly, :monthly, :fortnightly, '4 weekly'].sample }
    start_date { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    amount { Faker::Commerce.price(range: 10...100) }
    initial_payment_date { nil }
    initial_payment_amount { nil }

    factory :live_agreement do
      current_state { 'live' }
    end

    factory :breached_agreement do
      current_state { 'breached' }
    end

    factory :cancelled_agreement do
      current_state { 'cancelled' }
    end

    factory :completed_agreement do
      current_state { 'completed' }
    end

    trait :variable_payment do
      initial_payment_date { start_date - 1.day }
      initial_payment_amount { Faker::Commerce.price(range: 100...200) }
    end
  end

  factory :agreement_state, class: Hackney::Income::Models::AgreementState do
    agreement
    agreement_state { %i[live breached].sample }
    expected_balance { Faker::Commerce.price(range: 100...1000) }
    checked_balance { Faker::Commerce.price(range: 100...1000) }
    description { Faker::ChuckNorris.fact }

    trait :live do
      agreement_state { :live }
      expected_balance { Faker::Commerce.price(range: 100...1000) }
      checked_balance { expected_balance }
      description { Faker::ChuckNorris.fact }
      association :agreement, factory: %i[live_agreement]
    end

    trait :breached do
      agreement_state { :breached }
      expected_balance { Faker::Commerce.price(range: 100...1000) }
      checked_balance { expected_balance + 100 }
      description { Faker::ChuckNorris.fact }
      association :agreement, factory: %i[breached_agreement]
    end

    trait :cancelled do
      agreement_state { :cancelled }
      association :agreement, factory: %i[cancelled_agreement]
    end

    trait :completed do
      agreement_state { :completed }
      checked_balance { 0 }
      association :agreement, factory: %i[completed_agreement]
    end
  end
end
