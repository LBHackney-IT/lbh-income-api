module Hackney
  module ServiceCharge
    class UniversalHousingCriteria
      def self.for_lease(universal_housing_client, tenancy_ref)
        attributes = universal_housing_client[build_sql, tenancy_ref].first
        attributes ||= {}

        new(tenancy_ref, attributes.symbolize_keys)
      end

      def initialize(tenancy_ref, attributes)
        @tenancy_ref = tenancy_ref
        @attributes = attributes
      end

      def patch_code
        attributes.fetch(:patch_code)
      end

      def payment_ref
        attributes[:payment_ref].strip
      end

      def lessee
        attributes[:lessee].strip
      end

      def tenure_type
        attributes[:tenure_type].strip
      end

      def balance
        attributes[:balance].to_f
      end

      def property_address
        "#{attributes[:property_address_line_1].strip}, London, #{attributes[:property_post_code].strip}"
      end

      def latest_letter
        attributes[:latest_letter]
      end

      def latest_letter_date
        attributes[:latest_letter_date]
      end

      def direct_debit_status
        attributes[:direct_debit_status].strip
      end

      def self.format_letter_action_codes_for_sql
        Hackney::Tenancy::ActionCodes::FOR_UH_LEASEHOLD_SQL.map { |action_code| "('#{action_code}')" }.join(', ')
      end

      def self.build_last_letter_sql_query(column:)
        <<-SQL
          SELECT TOP 1 #{column}
          FROM araction WITH (NOLOCK)
          WHERE tag_ref = @TenancyRef
          AND (
            action_code IN (SELECT letter_codes FROM @LetterCodes)
          )
          ORDER BY action_date DESC
        SQL
      end

      def self.build_sql
        <<-SQL
          DECLARE @TenancyRef VARCHAR(60) = ?

          DECLARE @LetterCodes table(letter_codes varchar(60))
          INSERT INTO @LetterCodes VALUES #{format_letter_action_codes_for_sql}

          DECLARE @LastLetterActionCode VARCHAR(60) = (
            #{build_last_letter_sql_query(column: 'action_code')}
          )

          DECLARE @LastLetterDate SMALLDATETIME = (
            #{build_last_letter_sql_query(column: 'action_date')}
          )

          DECLARE @DirectDebitStatus VARCHAR(60) = (
            SELECT
              lookup_DDS.lu_desc
            FROM
              ddagacc
              INNER JOIN
                ddagree
                ON ddagacc.ddagree_ref = ddagree.ddagree_ref
              LEFT JOIN
                lookup as lookup_DDS
                ON ddagree.ddagree_status = lookup_DDS.lu_ref
                AND lookup_DDS.lu_type = 'DDS'
            WHERE
              ddagacc.tag_ref = @TenancyRef
              AND ddagree.ddagree_status < '400'
            )

          SELECT
            tenagree.cur_bal as balance,
            tenagree.u_saff_rentacc as payment_ref,
            property.arr_patch as patch_code,
            property.address1 as property_address_line_1,
            property.post_code as property_post_code,
            househ.house_desc as lessee,
            tenure.ten_desc as tenure_type,
            @DirectDebitStatus as direct_debit_status,
            @LastLetterActionCode as latest_letter,
            @LastLetterDate as latest_letter_date
          FROM [dbo].[tenagree] WITH (NOLOCK)
            LEFT OUTER JOIN [dbo].[tenure] On [dbo].[tenure].ten_type = [dbo].[tenagree].tenure
            LEFT OUTER JOIN [dbo].[property] WITH (NOLOCK) ON [dbo].[property].prop_ref = [dbo].[tenagree].prop_ref
            LEFT OUTER JOIN [dbo].[househ] WITH (NOLOCK) ON [dbo].[househ].house_ref = [dbo].[tenagree].house_ref
          WHERE tag_ref = @TenancyRef
        SQL
      end

      private

      attr_reader :tenancy_ref, :attributes
    end
  end
end
