module Hackney
  module Domain
    # What a NOSP is:
    #
    # Expires Date is when the NOSP can now be actioned upon.
    #   The Tenant has 28 days to pay the arrears before Court action can take place.
    #   This is the "cooling off period".
    #
    # Served - This is when there is a date from UH
    # Cool off Period - This is the period from NOSP served to 28 days after
    # Active - This when the Tenant can be taken to court if the arrears are "high" enough; after
    #          the cooling off period.
    # Valid - This is during the cooling off period and when the NOSP is "active".
    class Nosp
      attr_reader :served_date, :expires_date, :valid_until_date

      def initialize(served_date:, active_time: 28.days)
        @served_date = served_date

        calculate_properties(active_time: active_time)
      end

      def served?
        @served_date.present?
      end

      def active?
        @active || false
      end

      def valid?
        @valid || false
      end

      def in_cool_off_period?
        @in_cool_off_period || false
      end

      private

      def calculate_properties(active_time:)
        return unless served?

        @expires_date = @served_date + active_time
        @valid_until_date = @expires_date + 52.weeks
        @in_cool_off_period = @expires_date > Time.zone.now
        @valid = @valid_until_date > Time.zone.now
        @active = @valid && @expires_date < Time.zone.now
      end
    end
  end
end
