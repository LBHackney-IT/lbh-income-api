module CaseHelper
  def example_case(options = {})
    {
      "tenancy_ref": options.fetch(:tenancy_ref, Faker::Lorem.characters(number: 5)),
      "correspondence_address_1": options.fetch(:correspondence_address_1, Faker::Address.street_address),
      "correspondence_address_2": options.fetch(:correspondence_address_2, Faker::Address.secondary_address),
      "correspondence_address_3": options.fetch(:correspondence_address_3, Faker::Address.city),
      "correspondence_postcode": options.fetch(:correspondence_postcode, Faker::Address.zip_code),
      "property_address": options.fetch(:property_address, '1 Hillman St, London, E8 1DY'),
      "payment_ref": options.fetch(:payment_ref, Faker::Number.number(digits: 10)),
      "balance": options.fetch(:balance, Faker::Number.decimal(l_digits: 4, r_digits: 2)),
      "collectable_arrears_balance": options.fetch(:collectable_arrears_balance, Faker::Number.decimal(l_digits: 4, r_digits: 2)),
      "lba_expiry_date": options.fetch(:lba_expiry_date, ''),
      "original_lease_date": options.fetch(:original_lease_date, Faker::Date.between(from: 10.years.ago, to: Date.today)),
      "date_of_current_purchase_assignment": options.fetch(:date_of_current_purchase_assignment, Faker::Date.between(from: 10.years.ago, to: Date.today)),
      "original_Leaseholders": options.fetch(:original_Leaseholders, Faker::Name.name),
      "full_names_of_current_lessees": options.fetch(:full_names_of_current_lessees, [Faker::Name.name]),
      "previous_letter_sent": options.fetch(:previous_letter_sent, ''),
      "arrears_letter_1_date": options.fetch(:arrears_letter_1_date, '')
    }
  end
end
