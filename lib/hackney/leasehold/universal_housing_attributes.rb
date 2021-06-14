module Hackney
  module Leasehold
    class UniversalHousingAttributes
      def self.for_lease(universal_housing_client, tenancy_ref)
        result_from_sql = universal_housing_client[build_sql, tenancy_ref].first
        result_from_sql ||= {}

        new(tenancy_ref, result_from_sql.symbolize_keys)
      end

      def initialize(tenancy_ref, result_from_sql)
        @tenancy_ref = tenancy_ref
        @attributes_of_sql_result = result_from_sql
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
        attributes_of_sql_result[:direct_debit_status]&.strip
      end

      def self.format_letter_action_codes_for_sql
        Hackney::Tenancy::ActionCodes::FOR_UH_LEASEHOLD_SQL.map { |action_code| "('#{action_code}')" }.join(', ')
      end

      def self.build_last_letter_sql_query(column:)
        <<-SQL
          SELECT TOP 1 #{column}
          FROM UHAraction WITH (NOLOCK)
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
            SELECT TOP 1
              lookup.lu_desc
            FROM
              UHDdagacc ddagacc
              INNER JOIN
                UHDdagree ddagree
                ON ddagacc.ddagree_ref = ddagree.ddagree_ref
              LEFT JOIN
                lookup
                ON ddagree.ddagree_status = lookup.lu_ref
                AND lookup.lu_type = 'DDS'
            WHERE ddagacc.tag_ref = @TenancyRef
            ORDER BY ddagree.ddstart DESC
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
          FROM [dbo].[MATenancyAgreement] tenagree WITH (NOLOCK)
            LEFT OUTER JOIN [dbo].[UHTenure] tenure On [dbo].[UHTenure].ten_type = [dbo].[MATenancyAgreement].tenure
            LEFT OUTER JOIN [dbo].[MAProperty] property WITH (NOLOCK) ON [dbo].[MAProperty].prop_ref = [dbo].[MATenancyAgreement].prop_ref
            LEFT OUTER JOIN [dbo].[UHHousehold] househ WITH (NOLOCK) ON [dbo].[UHHousehold].house_ref = [dbo].[MATenancyAgreement].house_ref
          WHERE tag_ref = @TenancyRef
        SQL
      end

      private

      attr_reader :tenancy_ref, :attributes_of_sql_result
    end
  end
end
