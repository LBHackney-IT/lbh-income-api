module Stubs
  class StubCriteria
    def initialize(attributes = {})
      @attributes = attributes
    end

    def days_since_last_payment
      attributes[:days_since_last_payment]
    end

    def last_communication_date
      attributes[:last_communication_date]
    end

    def last_communication_action
      attributes[:last_communication_action]
    end

    def universal_credit
      attributes[:universal_credit]
    end

    def uc_rent_verification
      attributes[:uc_verification_complete]
    end

    def uc_direct_payment_requested
      attributes[:uc_direct_payment_requested]
    end

    def uc_direct_payment_received
      attributes[:uc_direct_payment_received]
    end

    def court_outcome
      attributes[:court_outcome]
    end

    def balance
      attributes[:balance] || 100.00
    end

    def weekly_rent
      attributes[:weekly_rent] || 5.0
    end

    def nosp_served_date
      attributes[:nosp_served_date]
    end

    def nosp_expiry_date
      attributes[:nosp_expiry_date]
    end

    def courtdate
      attributes[:courtdate] || '2005-12-13 12:43:10'.to_date
    end

    def eviction_date
      attributes[:eviction_date] || '2007-09-20 10:30:00'.to_date
    end

    def patch_code
      attributes[:patch_code] || 'E01'
    end

    def broken_court_order?
      attributes[:broken_court_order] || false
    end

    def days_in_arrears
      attributes[:days_in_arrears] || 7
    end

    def active_agreement?
      attributes[:active_agreement] || false
    end

    def nosp_served?
      ((attributes[:nosps_in_last_year] || 0) > 0) ||
        attributes[:nosp_served] || false
    end

    def active_nosp?
      attributes[:active_nosp] || false
    end

    def number_of_broken_agreements
      attributes[:number_of_broken_agreements] || 0
    end

    def payment_amount_delta
      attributes[:payment_amount_delta] || 0
    end

    def payment_date_delta
      attributes[:payment_date_delta] || 0
    end

    private

    attr_reader :attributes
  end
end
