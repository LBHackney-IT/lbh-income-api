FactoryBot.define do
  factory :leasehold_action, class: Hackney::IncomeCollection::Action do
    transient do
      property_address { "#{Faker::Address.street_address}, London, #{Faker::Address.postcode}" }
      lessee { Faker::Name.name }
      tenure_type { Faker::Music::RockBand.name }
      direct_debit_status { ['Live', 'First Payment', 'Cancelled', 'Last Payment'].sample }
      latest_letter { Hackney::Tenancy::ActionCodes::FOR_UH_LEASEHOLD_SQL.sample }
      latest_letter_date { Faker::Date.between(from: 20.days.ago, to: Date.today).to_s }
    end

    tenancy_ref { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
    balance { Faker::Number.decimal(l_digits: 3, r_digits: 3) }
    payment_ref { Faker::Number.number(digits: 10).to_s }
    patch_code { Faker::Alphanumeric.alpha(number: 3).upcase }
    action_type { tenure_type }
    service_area_type { Hackney::Leasehold::StoredActionGateway::SERVICE_AREA }
    metadata {
      {
        property_address: property_address,
        lessee: lessee,
        tenure_type: tenure_type,
        direct_debit_status: direct_debit_status,
        latest_letter: latest_letter,
        latest_letter_date: latest_letter_date
      }
    }
  end
end
