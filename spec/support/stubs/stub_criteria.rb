module Stubs
  class StubCriteria
    attr_writer :balance, :broken_court_order, :days_in_arrears,
                :number_of_broken_agreements,
                :payment_date_delta, :payment_amount_delta,
                :active_agreement, :active_nosp, :nosp_served_date,
                :nosp_expiry_date, :patch_code, :courtdate

    attr_accessor :days_since_last_payment, :last_communication_date, :paused, :nosp_served,
                  :last_communication_action, :court_outcome

    def balance
      @balance || 100.00
    end

    def weekly_rent
      5.0
    end

    def nosp_served_date
      '2019-12-13 12:43:10'.to_date
    end

    def nosp_expiry_date
      '2019-12-30 16:43:10'.to_date
    end

    def courtdate
      '2005-12-13 12:43:10'.to_date
    end

    def patch_code
      @patch_code || 'E01'
    end

    def broken_court_order?
      @broken_court_order || false
    end

    def days_in_arrears
      @days_in_arrears || 7
    end

    def active_agreement?
      @active_agreement || false
    end

    def nosp_served?
      @nosp_served || false
    end

    def active_nosp?
      @active_nosp || false
    end

    def number_of_broken_agreements
      @number_of_broken_agreements || 0
    end

    def payment_amount_delta
      @payment_amount_delta || 0
    end

    def payment_date_delta
      @payment_date_delta || 0
    end
  end
end
