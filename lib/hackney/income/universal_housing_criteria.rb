module Hackney
  module Income
    class UniversalHousingCriteria
      def self.for_tenancy(universal_housing_client, tenancy_ref)
        attributes = universal_housing_client[build_sql, tenancy_ref].first
        attributes ||= {}

        new(tenancy_ref, attributes.symbolize_keys)
      end

      def initialize(tenancy_ref, attributes)
        @tenancy_ref = tenancy_ref
        @attributes = attributes
      end

      def balance
        attributes.fetch(:current_balance).to_f
      end

      def weekly_rent
        attributes.fetch(:weekly_rent).to_f
      end

      def weekly_service
        attributes.fetch(:weekly_service).to_f
      end

      def weekly_other_charge
        attributes.fetch(:weekly_other_charge).to_f
      end

      def weekly_gross_rent
        weekly_rent + weekly_service + weekly_other_charge
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

      def courtdate
        return nil if date_not_valid?(attributes[:courtdate])

        attributes[:courtdate].to_date
      end

      def court_outcome
        attributes[:court_outcome]
      end

      def eviction_date
        return nil if date_not_valid?(attributes[:eviction_date])

        attributes[:eviction_date]
      end

      def days_since_last_payment
        return nil if attributes.fetch(:last_payment_date).nil?

        day_difference(Date.today, attributes.fetch(:last_payment_date))
      end

      def last_communication_action
        attributes[:last_communication_action]
      end

      def last_communication_date
        attributes[:last_communication_date]
      end

      def active_agreement?
        return false if attributes[:most_recent_agreement_status].blank?

        attributes[:most_recent_agreement_status].squish != Hackney::Income::BREACHED_ARREARS_AGREEMENT_STATUS
      end

      # FIXME: implementation needs confirming, will return to later
      def broken_court_order?
        false
      end

      def patch_code
        attributes.fetch(:patch_code)
      end

      def payment_ref
        attributes[:payment_ref].strip
      end

      def most_recent_agreement
        {
          breached: !active_agreement?,
          start_date: attributes[:most_recent_agreement_date]
        }
      end

      def total_payment_amount_in_week
        attributes[:total_payment_amount_in_week].to_f
      end

      def nosp_served_date
        return nil if date_not_valid?(attributes[:nosp_served_date])

        attributes[:nosp_served_date].to_date
      end

      def nosp_expiry_date
        nosp.expires_date
      end

      def nosp_served?
        nosp.served?
      end

      def active_nosp?
        nosp.active?
      end

      def nosp
        @nosp ||= Hackney::Domain::Nosp.new(served_date: nosp_served_date)
      end

      def self.format_action_codes_for_sql
        Hackney::Tenancy::ActionCodes::FOR_UH_CRITERIA_SQL.map { |action_code| "('#{action_code}')" }
                                                          .join(', ')
      end

      def self.build_last_communication_sql_query(column:)
        letter_2_sent_action_comment_text = 'Policy generated'

        <<-SQL
          SELECT TOP 1 #{column}
          FROM araction WITH (NOLOCK)
          WHERE tag_ref = @TenancyRef
          AND (
            action_code IN (SELECT communication_types FROM @CommunicationTypes) OR
            (
              action_code = '#{Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH}' AND
              action_comment collate SQL_Latin1_General_CP1_CI_AS LIKE '%#{letter_2_sent_action_comment_text}%'
            )
          )
          ORDER BY action_date DESC
        SQL
      end

      def self.build_sql
        <<-SQL
          DECLARE @TenancyRef VARCHAR(60) = ?
          DECLARE @PaymentTypes table(payment_type varchar(3))
          INSERT INTO @PaymentTypes VALUES ('RBA'), ('RBP'), ('RBR'), ('RCI'), ('RCO'), ('RCP'), ('RDD'), ('RDN'), ('RDP'), ('RDR'), ('RDS'), ('RDT'), ('REF'), ('RHA'), ('RHB'), ('RIT'), ('RML'), ('RPD'), ('RPO'), ('RPY'), ('RQP'), ('RRC'), ('RRP'), ('RSO'), ('RTM'), ('RUC'), ('RWA')
          DECLARE @CommunicationTypes table(communication_types varchar(60))
          INSERT INTO @CommunicationTypes VALUES #{format_action_codes_for_sql}

          DECLARE @LastPaymentDate SMALLDATETIME = (
            SELECT post_date FROM (
              SELECT ROW_NUMBER() OVER (ORDER BY post_date DESC) AS row, post_date
              FROM [dbo].[rtrans] WITH (NOLOCK)
              WHERE tag_ref = @TenancyRef
              AND trans_type IN (SELECT payment_type FROM @PaymentTypes)
            ) t
            WHERE row = 1
          )

          DECLARE @TotalPaymentAmountInWeek NUMERIC(9,2) = (
            SELECT total_amount_in_week FROM (
              SELECT SUM(real_value) as total_amount_in_week
              FROM [dbo].[rtrans] WITH (NOLOCK)
              WHERE tag_ref = @TenancyRef
              AND trans_type IN (SELECT payment_type FROM @PaymentTypes)
              AND post_date >= '#{beginning_of_week}'
            ) a
          )

          DECLARE @LastCommunicationAction VARCHAR(60) = (
            #{build_last_communication_sql_query(column: 'action_code')}
          )

          DECLARE @LastCommunicationDate SMALLDATETIME = (
            #{build_last_communication_sql_query(column: 'action_date')}
          )

          DECLARE @UniversalCredit SMALLDATETIME = (
            SELECT TOP 1 action_date
            FROM araction WITH (NOLOCK)
            WHERE tag_ref = @TenancyRef
            AND action_code = 'UCC'
            ORDER BY action_date DESC
          )
          DECLARE @UCVerificationComplete SMALLDATETIME = (
            SELECT TOP 1 action_date
            FROM araction WITH (NOLOCK)
            WHERE tag_ref = @TenancyRef
            AND action_code = 'UC1'
            ORDER BY action_date DESC
          )
          DECLARE @UCDirectPaymentRequested SMALLDATETIME = (
            SELECT TOP 1 action_date
            FROM araction WITH (NOLOCK)
            WHERE tag_ref = @TenancyRef
            AND action_code = 'UC2'
            ORDER BY action_date DESC
          )
          DECLARE @UCDirectPaymentReceived SMALLDATETIME = (
            SELECT TOP 1 action_date
            FROM araction WITH (NOLOCK)
            WHERE tag_ref = @TenancyRef
            AND action_code = 'UC3'
            ORDER BY action_date DESC
          )
          DECLARE @MostRecentAgreementDate SMALLDATETIME = (
            SELECT TOP 1 arag_startdate
            FROM [dbo].[arag] WITH (NOLOCK)
            WHERE tag_ref = @TenancyRef
            ORDER BY arag_startdate DESC
          )
          DECLARE @MostRecentAgreementStatus CHAR(10) = (
            SELECT TOP 1 arag_status
            FROM [dbo].[arag] WITH (NOLOCK)
            WHERE tag_ref = @TenancyRef
            ORDER BY arag_startdate DESC
          )

          SELECT
            tenagree.cur_bal as current_balance,
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
          WHERE tag_ref = @TenancyRef
        SQL
      end

      def self.beginning_of_week
        Time.zone.now.beginning_of_week.to_date.iso8601
      end

      private

      attr_reader :tenancy_ref, :attributes

      def day_difference(date_a, date_b)
        (date_a.to_date - date_b.to_date).to_i
      end

      def date_not_valid?(date)
        date == '1900-01-01 00:00:00 +0000'.to_time || date.nil?
      end
    end
  end
end
