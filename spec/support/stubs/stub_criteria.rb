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

    def latest_active_agreement_date
      attributes[:latest_active_agreement_date]
    end

    def breach_agreement_date
      attributes[:breach_agreement_date]
    end

    def balance
      attributes[:balance] || 100.00
    end

    def expected_balance
      attributes[:expected_balance] || 100.00
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
      attributes[:courtdate]
    end

    def eviction_date
      attributes[:eviction_date]
    end

    def patch_code
      attributes[:patch_code]
    end

    def broken_court_order?
      attributes[:broken_court_order]
    end

    def days_in_arrears
      attributes[:days_in_arrears] || 7
    end

    def active_agreement?
      attributes[:active_agreement]
    end

    def nosp_served?
      ((attributes[:nosps_in_last_year] || 0) > 0) ||
        attributes[:nosp_served] || false
    end

    def active_nosp?
      attributes[:active_nosp]
    end

    def number_of_broken_agreements
      attributes[:number_of_broken_agreements] || 0
    end

    def payment_ref
      attributes[:payment_ref]
    end

    private

    attr_reader :attributes
  end
end
