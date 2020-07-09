module Stubs
  class StubLeaseholdCriteria
    def initialize(attributes = { })
      @attributes_of_sql_result = attributes.reverse_merge(
        balance: Faker::Number.decimal(l_digits: 3, r_digits: 3),
        payment_ref: Faker::Number.number(digits: 10).to_s,
        patch_code: Faker::Alphanumeric.alpha(number: 3).upcase,
        property_address_line_1: Faker::Address.street_address,
        property_post_code: Faker::Address.postcode,
        lessee: Faker::Name.name,
        tenure_type: Faker::Music::RockBand.name,
        direct_debit_status: ['Live', 'First Payment', 'Cancelled', 'Last Payment'].sample,
        latest_letter: Hackney::Tenancy::ActionCodes::FOR_UH_LEASEHOLD_SQL.sample,
        latest_letter_date: Faker::Date.between(from: 20.days.ago, to: Date.today).to_s
      )
    end

    def patch_code
      attributes_of_sql_result.fetch(:patch_code)
    end

    def payment_ref
      attributes_of_sql_result[:payment_ref].strip
    end

    def lessee
      attributes_of_sql_result[:lessee].strip
    end

    def tenure_type
      attributes_of_sql_result[:tenure_type].strip
    end

    def balance
      attributes_of_sql_result[:balance].to_f
    end

    def property_address
      "#{attributes_of_sql_result[:property_address_line_1].strip}, London, #{attributes_of_sql_result[:property_post_code].strip}"
    end

    def latest_letter
      attributes_of_sql_result[:latest_letter]
    end

    def latest_letter_date
      attributes_of_sql_result[:latest_letter_date]
    end

    def direct_debit_status
      attributes_of_sql_result[:direct_debit_status].strip
    end

    private

    attr_reader :attributes_of_sql_result
  end
end
