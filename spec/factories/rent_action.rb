FactoryBot.define do
  factory :rent_action, class: Hackney::IncomeCollection::Action do
    transient do
      collectable_arrears { Faker::Number.decimal(l_digits: 3) }
      weekly_rent { Faker::Number.decimal(l_digits: 2) }
      nosp_served { false }
      nosp_served_date { nil }
      active_nosp { false }
      last_communication_action { nil }
      last_communication_date { nil }
      courtdate { nil }
      court_outcome { nil }
      eviction_date { nil }
      universal_credit { nil }
      uc_rent_verification { nil }
      uc_direct_payment_requested { nil }
      uc_direct_payment_received { nil }
      days_since_last_payment { Faker::Number.digit }
    end

    tenancy_ref { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
    balance { Faker::Number.decimal(l_digits: 3, r_digits: 3) }
    payment_ref { Faker::Number.number(digits: 10).to_s }
    patch_code { Faker::Alphanumeric.alpha(number: 3).upcase }
    action_type { Hackney::Income::WorktrayItemGateway::SECURE_TENURE_TYPE }
    service_area_type { Hackney::Income::WorktrayItemGateway::SERVICE_AREA }

    pause_reason { nil }
    pause_comment { nil }
    pause_until { nil }

    metadata {
      {
        collectable_arrears: collectable_arrears,
        weekly_rent: weekly_rent,
        nosp_served: nosp_served,
        nosp_served_date: nosp_served_date,
        active_nosp: active_nosp,
        last_communication_action: last_communication_action,
        last_communication_date: last_communication_date,
        courtdate: courtdate,
        court_outcome: court_outcome,
        eviction_date: eviction_date,
        universal_credit: universal_credit,
        uc_rent_verification: uc_rent_verification,
        uc_direct_payment_requested: uc_direct_payment_requested,
        uc_direct_payment_received: uc_direct_payment_received,
        days_since_last_payment: days_since_last_payment
      }
    }
  end
end
