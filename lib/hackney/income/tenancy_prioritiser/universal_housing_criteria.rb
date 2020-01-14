module Hackney
  module Income
    class TenancyPrioritiser
      class UniversalHousingCriteria
        def self.for_tenancy(universal_housing_client, tenancy_ref)
          attributes = universal_housing_client[
            build_sql,
            tenancy_ref,
            Hackney::Income::ACTIVE_ARREARS_AGREEMENT_STATUS,
            Hackney::Income::BREACHED_ARREARS_AGREEMENT_STATUS,
            Hackney::Income::NOSP_ACTION_DIARY_CODE
          ]

          new(tenancy_ref, attributes.first.symbolize_keys)
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

        def nosp_served_date
          return nil if date_not_valid?(attributes[:nosp_served_date])

          attributes[:nosp_served_date].to_date
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

        def nosp_expiry_date
          return nil if date_not_valid?(attributes[:nosp_expiry_date])

          attributes[:nosp_expiry_date].to_date
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

        def days_in_arrears
          day_difference(Date.today, attributes.fetch(:arrears_start_date))
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

        def number_of_broken_agreements
          attributes.fetch(:breached_agreements_count)
        end

        def nosp_served?
          attributes.fetch(:nosps_in_last_year) > 0
        end

        def active_nosp?
          attributes.fetch(:nosps_in_last_month) > 0
        end

        # FIXME: implementation needs confirming, will return to later
        def broken_court_order?
          false
        end

        def patch_code
          attributes.fetch(:patch_code)
        end

        def breach_agreement_date
          attributes.fetch(:breach_agreement_date)
        end

        def latest_active_agreement_date
          attributes[:latest_active_agreement_date]
        end

        def expected_balance
          attributes[:expected_balance]
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
            DECLARE @ActiveArrearsAgreementStatus VARCHAR(60) = ?
            DECLARE @BreachedArrearsAgreementStatus VARCHAR(60) = ?
            DECLARE @NospActionDiaryCode VARCHAR(60) = ?
            DECLARE @PaymentTypes table(payment_type varchar(3))
            INSERT INTO @PaymentTypes VALUES ('RBA'), ('RBP'), ('RBR'), ('RCI'), ('RCO'), ('RCP'), ('RDD'), ('RDN'), ('RDP'), ('RDR'), ('RDS'), ('RDT'), ('REF'), ('RHA'), ('RHB'), ('RIT'), ('RML'), ('RPD'), ('RPO'), ('RPY'), ('RQP'), ('RRC'), ('RRP'), ('RSO'), ('RTM'), ('RUC'), ('RWA')
            DECLARE @CommunicationTypes table(communication_types varchar(60))
            INSERT INTO @CommunicationTypes VALUES #{format_action_codes_for_sql}

            DECLARE @CurrentBalance NUMERIC(9, 2) = (SELECT cur_bal FROM [dbo].[tenagree] WITH (NOLOCK) WHERE tag_ref = @TenancyRef)
            DECLARE @LastPaymentDate SMALLDATETIME = (
              SELECT post_date FROM (
                SELECT ROW_NUMBER() OVER (ORDER BY post_date DESC) AS row, post_date
                FROM [dbo].[rtrans] WITH (NOLOCK)
                WHERE tag_ref = @TenancyRef
                AND trans_type IN (SELECT payment_type FROM @PaymentTypes)
              ) t
              WHERE row = 1
            )
            DECLARE @ExpectedBalance NUMERIC(9, 2) = (
              SELECT TOP 1 arag_lastexpectedbal
              FROM [dbo].[arag]
              WHERE tag_ref = @TenancyRef
              ORDER BY arag_statusdate
            )
            DECLARE @NospServedDate SMALLDATETIME = (
              SELECT u_notice_served FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )
            DECLARE @NospExpiryDate SMALLDATETIME = (
              SELECT u_notice_expiry FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )
            DECLARE @Courtdate SMALLDATETIME = (
              SELECT courtdate FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )
            DECLARE @CourtOutcome VARCHAR(3) = (
              SELECT u_court_outcome FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )
            DECLARE @EvictionDate SMALLDATETIME = (
              SELECT evictdate FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )

            DECLARE @WeeklyRent NUMERIC(9, 2) = (
              SELECT rent FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )
            DECLARE @WeeklyService NUMERIC(9, 2) = (
              SELECT service FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )
            DECLARE @WeeklyOtherCharge NUMERIC(9, 2) = (
              SELECT other_charge FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )

            DECLARE @PaymentRef VARCHAR(20) = (
              SELECT u_saff_rentacc FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )
            DECLARE @PatchCode VARCHAR(3) = (
              SELECT arr_patch
              FROM [dbo].[property]
              INNER JOIN [dbo].[tenagree] ON [dbo].[property].prop_ref = [dbo].[tenagree].prop_ref
              WHERE tag_ref = @TenancyRef
            )

            DECLARE @RemainingTransactions INT = (SELECT COUNT(tag_ref) FROM [dbo].[rtrans] WITH (NOLOCK) WHERE tag_ref = @TenancyRef)
            DECLARE @ActiveAgreementsCount INT = (SELECT COUNT(tag_ref) FROM [dbo].[arag] WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND arag_status = @ActiveArrearsAgreementStatus)
            DECLARE @BreachedAgreementsCount INT = (SELECT COUNT(tag_ref) FROM [dbo].[arag] WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND arag_status = @BreachedArrearsAgreementStatus)
            DECLARE @NospsInLastYear INT = (SELECT COUNT(tag_ref) FROM araction WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND action_code = @NospActionDiaryCode AND action_date >= CONVERT(date, DATEADD(year, -1, GETDATE())))
            DECLARE @NospsInLastMonth INT = (SELECT COUNT(tag_ref) FROM araction WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND action_code = @NospActionDiaryCode AND action_date >= CONVERT(date, DATEADD(month, -1, GETDATE())))

            DECLARE @LastCommunicationAction VARCHAR(60) = (
              #{build_last_communication_sql_query(column: 'action_code')}
            )

            DECLARE @LastCommunicationDate SMALLDATETIME = (
              #{build_last_communication_sql_query(column: 'action_date')}
            )

            DECLARE @UniversalCredit SMALLDATETIME = (
              SELECT TOP 1 action_date
              FROM araction
              WHERE tag_ref = @TenancyRef
              AND action_code = 'UCC'
              ORDER BY action_date DESC
            )
            DECLARE @UCVerificationComplete SMALLDATETIME = (
              SELECT TOP 1 action_date
              FROM araction
              WHERE tag_ref = @TenancyRef
              AND action_code = 'UC1'
              ORDER BY action_date DESC
            )
            DECLARE @UCDirectPaymentRequested SMALLDATETIME = (
              SELECT TOP 1 action_date
              FROM araction
              WHERE tag_ref = @TenancyRef
              AND action_code = 'UC2'
              ORDER BY action_date DESC
            )
            DECLARE @UCDirectPaymentReceived SMALLDATETIME = (
              SELECT TOP 1 action_date
              FROM araction
              WHERE tag_ref = @TenancyRef
              AND action_code = 'UC3'
              ORDER BY action_date DESC
            )
            DECLARE @LatestActiveAgreementDate SMALLDATETIME = (
              SELECT TOP 1 arag_startdate
              FROM [dbo].[arag]
              WHERE tag_ref = @TenancyRef
              AND arag_status = @ActiveArrearsAgreementStatus
              ORDER BY arag_startdate DESC
            )
            DECLARE @MostRecentAgreementDate SMALLDATETIME = (
              SELECT TOP 1 arag_startdate
              FROM [dbo].[arag]
              WHERE tag_ref = @TenancyRef
              ORDER BY arag_startdate DESC
            )
            DECLARE @MostRecentAgreementStatus CHAR(10) = (
              SELECT TOP 1 arag_status
              FROM [dbo].[arag]
              WHERE tag_ref = @TenancyRef
              ORDER BY arag_startdate DESC
            )

            DECLARE @BreachAgreementDate SMALLDATETIME = (
              SELECT TOP 1 arag_statusdate
              FROM [dbo].[arag]
              WHERE tag_ref = @TenancyRef
              AND arag_status = @BreachedArrearsAgreementStatus
              ORDER BY arag_statusdate DESC
            )
            DECLARE @NextBalance NUMERIC(9, 2) = @CurrentBalance
            DECLARE @CurrentTransactionRow INT = 1
            DECLARE @ArrearsStartDate SMALLDATETIME = GETDATE()
            WHILE (@NextBalance > 0 AND @RemainingTransactions > 0)
            BEGIN
              SELECT @NextBalance = @NextBalance - real_value, @ArrearsStartDate = post_date
              FROM (
                SELECT ROW_NUMBER() OVER (ORDER BY post_date DESC) as row, real_value, post_date
                FROM rtrans WITH (NOLOCK)
                WHERE tag_ref = @TenancyRef
              ) t
              WHERE row = @CurrentTransactionRow

              SET @RemainingTransactions = @RemainingTransactions - 1
              SET @CurrentTransactionRow = @CurrentTransactionRow + 1
            END

            SELECT
              @CurrentBalance as current_balance,
              @WeeklyRent as weekly_rent,
              @WeeklyService as weekly_service,
              @WeeklyOtherCharge as weekly_other_charge,
              @PatchCode as patch_code,
              @LastPaymentDate as last_payment_date,
              @ArrearsStartDate as arrears_start_date,
              @ActiveAgreementsCount as active_agreements_count,
              @BreachedAgreementsCount as breached_agreements_count,
              @NospsInLastYear as nosps_in_last_year,
              @NospsInLastMonth as nosps_in_last_month,
              @NospServedDate as nosp_served_date,
              @NospExpiryDate as nosp_expiry_date,
              @Courtdate as courtdate,
              @CourtOutcome as court_outcome,
              @LatestActiveAgreementDate as latest_active_agreement_date,
              @EvictionDate as eviction_date,
              @LastCommunicationAction as last_communication_action,
              @LastCommunicationDate as last_communication_date,
              @UniversalCredit as universal_credit,
              @UCVerificationComplete as uc_verification_complete,
              @UCDirectPaymentRequested as uc_direct_payment_requested,
              @UCDirectPaymentReceived as uc_direct_payment_received,
              @BreachAgreementDate as breach_agreement_date,
              @ExpectedBalance as expected_balance,
              @PaymentRef as payment_ref,
              @MostRecentAgreementDate as most_recent_agreement_date,
              @MostRecentAgreementStatus as most_recent_agreement_status
          SQL
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
end
