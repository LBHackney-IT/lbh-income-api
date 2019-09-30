module Hackney
  module Income
    class TenancyPrioritiser
      class UniversalHousingCriteria
        def self.for_tenancy(universal_housing_client, tenancy_ref)
          sql = <<-SQL
            DECLARE @TenancyRef VARCHAR(60) = ?
            DECLARE @ActiveArrearsAgreementStatus VARCHAR(60) = ?
            DECLARE @BreachedArrearsAgreementStatus VARCHAR(60) = ?
            DECLARE @NospActionDiaryCode VARCHAR(60) = ?
            DECLARE @PaymentTypes table(payment_type varchar(3))
            INSERT INTO @PaymentTypes VALUES ('RBA'), ('RBP'), ('RBR'), ('RCI'), ('RCO'), ('RCP'), ('RDD'), ('RDN'), ('RDP'), ('RDR'), ('RDS'), ('RDT'), ('REF'), ('RHA'), ('RHB'), ('RIT'), ('RML'), ('RPD'), ('RPO'), ('RPY'), ('RQP'), ('RRC'), ('RRP'), ('RSO'), ('RTM'), ('RUC'), ('RWA')

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
            DECLARE @NospServedDate SMALLDATETIME = (
              SELECT u_notice_served FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )
            DECLARE @NospExpiryDate SMALLDATETIME = (
              SELECT u_notice_expiry FROM [dbo].[tenagree] WHERE tag_ref = @TenancyRef
            )


            DECLARE @RemainingTransactions INT = (SELECT COUNT(tag_ref) FROM [dbo].[rtrans] WITH (NOLOCK) WHERE tag_ref = @TenancyRef)
            DECLARE @ActiveAgreementsCount INT = (SELECT COUNT(tag_ref) FROM [dbo].[arag] WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND arag_status = @ActiveArrearsAgreementStatus)
            DECLARE @BreachedAgreementsCount INT = (SELECT COUNT(tag_ref) FROM [dbo].[arag] WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND arag_status = @BreachedArrearsAgreementStatus)
            DECLARE @NospsInLastYear INT = (SELECT COUNT(tag_ref) FROM araction WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND action_code = @NospActionDiaryCode AND action_date >= CONVERT(date, DATEADD(year, -1, GETDATE())))
            DECLARE @NospsInLastMonth INT = (SELECT COUNT(tag_ref) FROM araction WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND action_code = @NospActionDiaryCode AND action_date >= CONVERT(date, DATEADD(month, -1, GETDATE())))

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

            DECLARE @Payment1Value NUMERIC(9, 2) = (SELECT real_value FROM (SELECT ROW_NUMBER() OVER(ORDER BY post_date DESC) as row, real_value FROM rtrans WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND trans_type IN (SELECT * FROM @PaymentTypes)) t WHERE row = 1)
            DECLARE @Payment1Date SMALLDATETIME = (SELECT post_date FROM (SELECT ROW_NUMBER() OVER(ORDER BY post_date DESC) as row, post_date FROM rtrans WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND trans_type IN (SELECT * FROM @PaymentTypes)) t WHERE row = 1)
            DECLARE @Payment2Value NUMERIC(9, 2) = (SELECT real_value FROM (SELECT ROW_NUMBER() OVER(ORDER BY post_date DESC) as row, real_value FROM rtrans WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND trans_type IN (SELECT * FROM @PaymentTypes)) t WHERE row = 2)
            DECLARE @Payment2Date SMALLDATETIME = (SELECT post_date FROM (SELECT ROW_NUMBER() OVER(ORDER BY post_date DESC) as row, post_date FROM rtrans WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND trans_type IN (SELECT * FROM @PaymentTypes)) t WHERE row = 2)
            DECLARE @Payment3Value NUMERIC(9, 2) = (SELECT real_value FROM (SELECT ROW_NUMBER() OVER(ORDER BY post_date DESC) as row, real_value FROM rtrans WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND trans_type IN (SELECT * FROM @PaymentTypes)) t WHERE row = 3)
            DECLARE @Payment3Date SMALLDATETIME = (SELECT post_date FROM (SELECT ROW_NUMBER() OVER(ORDER BY post_date DESC) as row, post_date FROM rtrans WITH (NOLOCK) WHERE tag_ref = @TenancyRef AND trans_type IN (SELECT * FROM @PaymentTypes)) t WHERE row = 3)

            SELECT
              @CurrentBalance as current_balance,
              @LastPaymentDate as last_payment_date,
              @ArrearsStartDate as arrears_start_date,
              @ActiveAgreementsCount as active_agreements_count,
              @BreachedAgreementsCount as breached_agreements_count,
              @NospsInLastYear as nosps_in_last_year,
              @NospsInLastMonth as nosps_in_last_month,
              @NospServedDate as nosp_served_date,
              @NospExpiryDate as nosp_expiry_date,
              @Payment1Value as payment_1_value,
              @Payment1Date as payment_1_date,
              @Payment2Value as payment_2_value,
              @Payment2Date as payment_2_date,
              @Payment3Value as payment_3_value,
              @Payment3Date as payment_3_date;
          SQL

          attributes = universal_housing_client[
            sql,
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

        def nosp_served_date
          return if attributes[:nosp_served_date].nil?

          attributes[:nosp_served_date].to_date
        end

        def nosp_expiry_date
          return nil if attributes[:nosp_served_date].nil?

          attributes[:nosp_expiry_date].to_date
        end

        def days_in_arrears
          day_difference(Date.today, attributes.fetch(:arrears_start_date))
        end

        def days_since_last_payment
          return nil if attributes.fetch(:last_payment_date).nil?

          day_difference(Date.today, attributes.fetch(:last_payment_date))
        end

        def active_agreement?
          attributes.fetch(:active_agreements_count) > 0
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

        def payment_amount_delta
          payment_amounts = [
            attributes.fetch(:payment_1_value),
            attributes.fetch(:payment_2_value),
            attributes.fetch(:payment_3_value)
          ].compact.map(&:to_f)

          return nil if payment_amounts.count < 3

          (payment_amounts[0] - payment_amounts[1]) - (payment_amounts[1] - payment_amounts[2])
        end

        def payment_date_delta
          payment_dates = [
            attributes.fetch(:payment_1_date),
            attributes.fetch(:payment_2_date),
            attributes.fetch(:payment_3_date)
          ].compact

          return nil if payment_dates.count < 3

          day_difference(payment_dates[0], payment_dates[1]) - day_difference(payment_dates[1], payment_dates[2])
        end

        # FIXME: implementation needs confirming, will return to later
        def broken_court_order?
          false
        end

        private

        attr_reader :tenancy_ref, :attributes

        def day_difference(date_a, date_b)
          (date_a.to_date - date_b.to_date).to_i
        end
      end
    end
  end
end
