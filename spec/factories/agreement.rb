FactoryBot.define do
  factory :agreement, class: Hackney::Income::Models::Agreement do
    tenancy_ref { Faker::Lorem.characters(number: 5) }
    agreement_type { :informal }
    notes { Faker::ChuckNorris.fact }
    created_by { Faker::Name.name }
    frequency { [:weekly, :monthly, :fortnightly, '4 weekly'].sample }
    start_date { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    amount { Faker::Commerce.price(range: 10...100) }
  end

  factory :agreement_state, class: Hackney::Income::Models::AgreementState do
    agreement
    agreement_state { :live }

    trait :live do
      agreement_state { :live }
    end

    trait :breached do
      agreement_state { :breached }
    end

    trait :cancelled do
      agreement_state { :cancelled }
    end

    trait :completed do
      agreement_state { :completed }
    end
  end
end
