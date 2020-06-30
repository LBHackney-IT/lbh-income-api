module Stubs
  class StubServiceChargeCriteria
    def initialize(attributes = {})
      @attributes = attributes
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

    attr_reader :attributes
  end
end
