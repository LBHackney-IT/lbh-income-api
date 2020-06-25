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
        <<~SQL
          SELECT
            property.arr_patch AS Patch,
            RTrim(u_saff_rentacc) AS [Payment Ref],
            tenagree.tag_ref AS [UH Acct No],
            RTrim(house_desc) AS Lessee,
            RTrim(property.address1) + ', London, ' + RTrim(property.post_code) AS [Property Address],
            tenagree.prop_ref AS [Property Ref],
            RTrim(ten_desc) AS Tenures,
            Rtrim(lookup_ZAC.lu_desc) AS [Account Type],
            ISNULL(RTrim(ddag.ag_status), '') AS [DD Status],
            ISNULL(SUBSTRING(bco_ref, 6, 2), '') AS [Pay Day],
            ISNULL(CASE
                    WHEN
                      fixed_total_due != 0
                    THEN
                      fixed_total_due
                    ELSE
                      due_per_period
                  END, 0) AS [DD Payment],
            GETDATE() - 1 AS [Arrears Date],
            mthdeb.[total debit] AS [Monthly Debit],
            tenagree.cur_bal AS Balance,
            cur_bal + (( CASE
                          WHEN
                            payments_remaining > 0
                          THEN
                            CASE
                              WHEN
                                payments_remaining < (12 - rg_period_no)
                              THEN
                                payments_remaining
                              ELSE
                      (12 - rg_period_no)
                            END
                            ELSE
                              0
                        END ) * [total debit]) - SumOfmw_mth_pay AS Arrears,
            ISNULL( - m0.SumOfreal_value, 0) AS [Paid this month],
            ISNULL( - m1.SumOfreal_value, 0) AS [Paid last month],
            ISNULL( - m2.SumOfreal_value, 0) AS [Paid previous month],
            arlet.LastOfact_name AS [Latest Letter]
            arlet.MaxOfaction_date AS [Letter Date],
            ISNULL(u_bal_dispute, 0) AS [Disputed Bal],
            ISNULL(u_referred_legal, 0) AS [Excl from Arr Pol],
            ISNULL(u_charging_order, 0) AS [Chg Order],
            ISNULL(u_money_judgement, 0) AS Judgement,
            corr_addr.Address_1 AS Corr_add_1,
            corr_addr.Address_2 AS Corr_add_2,
            corr_addr.Address_3 AS Corr_add_3,
            corr_addr.Address_4 + CASE
                                    WHEN
                                      corr_addr.Address_5 != ''
                                    THEN
                                      ', ' + corr_addr.Address_5
                                    ELSE
                                      ''
                                  END AS Corr_add_4, corr_addr.Postcode AS Corr_postcode
          FROM
            tenagree
            INNER JOIN
              property
              ON tenagree.prop_ref = property.prop_ref
            INNER JOIN
              househ
              ON property.prop_ref = househ.prop_ref
              AND tenagree.house_ref = househ.house_ref
            INNER JOIN
              tenure
              ON tenagree.tenure = tenure.ten_type
            INNER JOIN
              rentgrp
              ON tenagree.rentgrp_ref = rentgrp.rentgrp_ref
            INNER JOIN
              (
                SELECT
                  tenagree.tag_ref,
                  CASE
                    WHEN
                      RTrim(corr_postcode) != ''
                    THEN
                      CASE
                        WHEN
                          RTrim(corr_preamble) != ''
                        THEN
                          RTrim(corr_preamble)
                        ELSE
                          CASE
                            WHEN
                              RTrim(corr_desig) != ''
                            THEN
                              RTrim(corr_desig) + ' ' + RTrim(postcode_1.aline1)
                            ELSE
                              RTrim(postcode_1.aline1)
                          END
                      END
                      ELSE
                        CASE
                          WHEN
                            RTrim(househ.post_preamble) != ''
                          THEN
                            RTrim(househ.post_preamble)
                          ELSE
                            CASE
                              WHEN
                                RTrim(househ.post_desig) != ''
                              THEN
                                RTrim(househ.post_desig) + ' ' + RTrim(postcode.aline1)
                              ELSE
                                RTrim(postcode.aline1)
                            END
                        END
                  END
                  AS Address_1,
                  CASE
                    WHEN
                      RTrim(corr_postcode) != ''
                    THEN
                      CASE
                        WHEN
                          RTrim(corr_preamble) != ''
                        THEN
                          CASE
                            WHEN
                              RTrim(corr_desig) != ''
                            THEN
                              RTrim(corr_desig) + ' ' + RTrim(postcode_1.aline1)
                            ELSE
                              RTrim(postcode_1.aline1)
                          END
                          ELSE
                            RTrim(postcode_1.aline2)
                      END
                      ELSE
                        CASE
                          WHEN
                            RTrim(househ.post_preamble) != ''
                          THEN
                            CASE
                              WHEN
                                RTrim(househ.post_desig) != ''
                              THEN
                                RTrim(househ.post_desig) + ' ' + RTrim(postcode.aline1)
                              ELSE
                                RTrim(postcode.aline1)
                            END
                            ELSE
                              RTrim(postcode.aline2)
                        END
                  END
                  AS Address_2,
                  CASE
                    WHEN
                      RTrim(corr_postcode) != ''
                    THEN
                      CASE
                        WHEN
                          RTrim(corr_preamble) != ''
                        THEN
                          RTrim(postcode_1.aline2)
                        ELSE
                          RTrim(postcode_1.aline3)
                      END
                      ELSE
                        CASE
                          WHEN
                            RTrim(househ.post_preamble) != ''
                          THEN
                            RTrim(postcode.aline2)
                          ELSE
                            RTrim(postcode.aline3)
                        END
                  END
                  AS Address_3,
                  CASE
                    WHEN
                      RTrim(corr_postcode) != ''
                    THEN
                      CASE
                        WHEN
                          RTrim(corr_preamble) != ''
                        THEN
                          RTrim(postcode_1.aline3)
                        ELSE
                          RTrim(postcode_1.[aline4])
                      END
                      ELSE
                        CASE
                          WHEN
                            RTrim(househ.post_preamble) != ''
                          THEN
                            RTrim(postcode.aline3)
                          ELSE
                            RTrim(postcode.aline4)
                        END
                  END
                  AS Address_4,
                  CASE
                    WHEN
                      RTrim(corr_postcode) != ''
                    THEN
                      CASE
                        WHEN
                          RTrim(corr_preamble) != ''
                        THEN
                          RTrim(postcode_1.aline4)
                        ELSE
                          ''
                      END
                      ELSE
                        CASE
                          WHEN
                            RTrim(househ.post_preamble) != ''
                          THEN
                            RTrim(postcode.aline4)
                          ELSE
                            ''
                        END
                  END
                  AS Address_5,
                  CASE
                    WHEN
                      RTrim(corr_postcode) != ''
                    THEN
                      RTrim(corr_postcode)
                    ELSE
                      RTrim(househ.post_code)
                  END
                  AS Postcode
                FROM
                  tenagree
                  INNER JOIN
                    househ
                    ON tenagree.house_ref = househ.house_ref
                    AND tenagree.prop_ref = househ.prop_ref
                  LEFT JOIN
                    postcode
                    ON househ.post_code = postcode.post_code
                  LEFT JOIN
                    postcode AS postcode_1
                    ON househ.corr_postcode = postcode_1.post_code
                WHERE
                  tenagree.rentgrp_ref = 'LSC'
                  AND tenagree.eot = '01/01/1900'
              )
              AS corr_addr
              ON tenagree.tag_ref = corr_addr.tag_ref
            LEFT JOIN
              (
                SELECT
                  lu_ref,
                  lu_desc
                FROM
                  lookup
                WHERE
                  lookup.lu_type = 'ZAC'
              )
              AS lookup_ZAC
              ON tenagree.acc_type = lookup_ZAC.lu_ref
            LEFT JOIN
              (
                SELECT
                  ddagacc.tag_ref,
                  ddagacc.due_per_period,
                  ddagacc.fixed_total_due,
                  ddagree.bco_ref,
                  tenagree.rentgrp_ref,
                  lookup_DDS.lu_desc AS ag_status
                FROM
                  ddagacc
                  INNER JOIN
                    ddagree
                    ON ddagacc.ddagree_ref = ddagree.ddagree_ref
                  INNER JOIN
                    tenagree
                    ON ddagacc.tag_ref = tenagree.tag_ref
                  LEFT JOIN
                    lookup as lookup_DDS
                    ON ddagree.ddagree_status = lookup_DDS.lu_ref
                    AND lookup_DDS.lu_type = 'DDS'
                WHERE
                  tenagree.rentgrp_ref = 'LSC'
                  AND ddagree.ddagree_status < '400'
              )
              AS ddag
              ON tenagree.tag_ref = ddag.tag_ref
            LEFT JOIN
              (
                SELECT
                  araction.tag_ref,
                  Max(raaction.act_name) AS LastOfact_name,
                  Max(araction.action_date) AS MaxOfaction_date
                FROM
                  araction
                  INNER JOIN
                    tenagree
                    ON araction.tag_ref = tenagree.tag_ref
                  INNER JOIN
                    raaction
                    ON araction.action_code = raaction.act_code
                WHERE
                  araction.action_code IN
                  (
                    'LL1',
                    'LL2',
                    'LF1',
                    'LF2',
                    'LS1',
                    'LS2'
                  )
                  AND tenagree.rentgrp_ref = 'LSC'
                GROUP BY
                  araction.tag_ref
              )
              AS arlet
              ON tenagree.tag_ref = arlet.tag_ref
            LEFT JOIN
              (
                SELECT
                  u_mwaragdet.tag_ref,
                  u_mwaragdet.mw_mth_pay,
                  Sum(u_mwaragdet.mw_mth_pay) AS SumOfmw_mth_pay,
                  Avg(u_mwaragdet.mw_mth_pay) AS AvgOfmw_mth_pay,
                  Sum([mw_mth_pay]) / Avg([mw_mth_pay]) AS payments_remaining
                FROM
                  u_mwaragdet
                  INNER JOIN
                    tenagree
                    ON u_mwaragdet.tag_ref = tenagree.tag_ref
                  INNER JOIN
                    rentgrp
                    ON tenagree.rentgrp_ref = rentgrp.rentgrp_ref
                WHERE
                  u_mwaragdet.mw_pay_date > GETDATE() - 1
                  AND tenagree.rentgrp_ref = 'LSC'
                GROUP BY
                  u_mwaragdet.tag_ref,
                  u_mwaragdet.mw_mth_pay
              )
              AS arag
              ON tenagree.tag_ref = arag.tag_ref
            LEFT JOIN
              (
                SELECT
                  debitem.prop_ref,
                  tenagree.tag_ref,
                  eff_date,
                  Sum(debitem.deb_value) AS [total debit],
                  Sum((12 - rg_period_no)*deb_value) AS [remaining debits]
                FROM
                  debitem
                  INNER JOIN
                    tenagree
                    ON debitem.prop_ref = tenagree.prop_ref
                  INNER JOIN
                    rentgrp
                    ON tenagree.rentgrp_ref = rentgrp.rentgrp_ref
                WHERE
                  debitem.prop_ref != ''
                  AND debitem.eff_date > CAST('03/31/' + CAST(rg_year - 1 AS CHAR)AS DATETIME)
                  AND
                  (
                    debitem.term_date = '01/01/1900'
                    OR debitem.term_date >= GETDATE()
                  )
                  AND tenagree.rentgrp_ref = 'LSC'
                  AND tenagree.eot = '01/01/1900'
                GROUP BY
                  debitem.prop_ref,
                  tenagree.tag_ref,
                  eff_date
              )
              as mthdeb
              ON tenagree.tag_ref = mthdeb.tag_ref
            LEFT JOIN
              (
                SELECT
                  rtrans.tag_ref,
                  Sum(rtrans.real_value) AS SumOfreal_value
                FROM
                  rtrans
                  INNER JOIN
                    tenagree
                    ON rtrans.tag_ref = tenagree.tag_ref
                  INNER JOIN
                    rentgrp
                    ON rtrans.rentgroup = rentgrp.rentgrp_ref
                WHERE
                  rtrans.prd_sno =
                  (
                    tenagree.prd_sno
                  )
                  AND rtrans.trans_type Like 'R%'
                  AND rtrans.rentgroup = 'LSC'
                  AND rtrans.post_year = [rg_year]
                GROUP BY
                  rtrans.tag_ref
              )
              AS m0
              ON tenagree.tag_ref = m0.tag_ref
            LEFT JOIN
              (
                SELECT
                  rtrans.tag_ref,
                  Sum(rtrans.real_value) AS SumOfreal_value
                FROM
                  rtrans
                  INNER JOIN
                    tenagree
                    ON rtrans.tag_ref = tenagree.tag_ref
                  INNER JOIN
                    rentgrp
                    ON rtrans.rentgroup = rentgrp.rentgrp_ref
                WHERE
                  rtrans.prd_sno =
                  (
                    tenagree.prd_sno - 1
                  )
                  AND rtrans.trans_type Like 'R%'
                  AND rtrans.rentgroup = 'LSC'
                  AND
                  (
                    rtrans.post_year = [rg_year]
                    Or rtrans.post_year = [rg_year] - 1
                  )
                GROUP BY
                  rtrans.tag_ref
              )
              AS m1
              ON tenagree.tag_ref = m1.tag_ref
            LEFT JOIN
              (
                SELECT
                  rtrans.tag_ref,
                  Sum(rtrans.real_value) AS SumOfreal_value
                FROM
                  rtrans
                  INNER JOIN
                    tenagree
                    ON rtrans.tag_ref = tenagree.tag_ref
                  INNER JOIN
                    rentgrp
                    ON rtrans.rentgroup = rentgrp.rentgrp_ref
                WHERE
                  rtrans.prd_sno =
                  (
                    tenagree.prd_sno - 2
                  )
                  AND rtrans.trans_type Like 'R%'
                  AND rtrans.rentgroup = 'LSC'
                  AND
                  (
                    rtrans.post_year = [rg_year]
                    Or rtrans.post_year = [rg_year] - 1
                  )
                GROUP BY
                  rtrans.tag_ref
              )
              AS m2
              ON tenagree.tag_ref = m2.tag_ref
          WHERE
            tenagree.rentgrp_ref = 'LSC'
            AND tenagree.tenure != 'FRE'
            AND tenagree.eot = '01/01/1900'
            AND
            (
              cur_bal + ((
              CASE
                WHEN
                  payments_remaining > 0
                THEN
                  CASE
                    WHEN
                      payments_remaining < (12 - rg_period_no)
                    THEN
                      payments_remaining
                    ELSE
          (12 - rg_period_no)
                  END
                  ELSE
                    0
              END
          ) * [total debit]) - SumOfmw_mth_pay
            )
            > 0
          ORDER BY
            property.arr_patch, u_saff_rentacc;
        SQL
      end

      private

      attr_reader :payment_ref, :attributes
    end
  end
end
