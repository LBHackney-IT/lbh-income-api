module Hackney
  module ServiceCharge
    class UniversalHousingCriteria
      def self.for_lease(universal_housing_client, payment_ref)
        attributes = universal_housing_client[build_sql, payment_ref].first
        attributes ||= {}

        new(payment_ref, attributes.symbolize_keys)
      end

      def initialize(payment_ref, attributes)
        @payment_ref = payment_ref
        @attributes = attributes
      end

      def patch_code
        attributes.fetch(:patch_code)
      end

      def payment_ref
        attributes[:payment_ref].strip
      end

      def tenancy_ref
        attributes[:tenancy_ref].strip
      end

      def self.format_action_codes_for_sql
        Hackney::Tenancy::ActionCodes::FOR_UH_CRITERIA_SQL.map { |action_code| "('#{action_code}')" }
                                                          .join(', ')
      end

      def self.build_sql
        <<-SQL

          SELECT
            property.arr_patch as patch_code,
            tenagree.rent as weekly_rent,
            tenagree.service as weekly_service,
            tenagree.other_charge as weekly_other_charge,
            tenagree.u_notice_served as nosp_served_date,
            tenagree.courtdate as courtdate,
            tenagree.u_court_outcome as court_outcome,
            tenagree.evictdate as eviction_date,
            tenagree.u_saff_rentacc as payment_ref,
            property.arr_patch as patch_code,
            @LastPaymentDate as last_payment_date,
            @LastCommunicationAction as last_communication_action,
            @LastCommunicationDate as last_communication_date,
            @UniversalCredit as universal_credit,
            @UCVerificationComplete as uc_verification_complete,
            @UCDirectPaymentRequested as uc_direct_payment_requested,
            @UCDirectPaymentReceived as uc_direct_payment_received,
            @MostRecentAgreementDate as most_recent_agreement_date,
            @MostRecentAgreementStatus as most_recent_agreement_status,
            @TotalPaymentAmountInWeek as total_payment_amount_in_week
          FROM [dbo].[tenagree] WITH (NOLOCK)
          LEFT OUTER JOIN [dbo].[property] WITH (NOLOCK) ON [dbo].[property].prop_ref = [dbo].[tenagree].prop_ref
          WHERE tag_ref = @Payment_ref
        SQL
      end

      def self.beginning_of_week
        Time.zone.now.beginning_of_week.to_date.iso8601
      end

      private

      attr_reader :payment_ref, :attributes

      def day_difference(date_a, date_b)
        (date_a.to_date - date_b.to_date).to_i
      end

      def date_not_valid?(date)
        date == '1900-01-01 00:00:00 +0000'.to_time || date.nil?
      end
    end
  end
end
