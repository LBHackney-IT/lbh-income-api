module Hackney
  module Income
    class UniversalHousingLeaseholdGateway
      def get_tenancy_ref(payment_ref:)
        with_core do |core|
          core.get_tenancy_ref(payment_ref: payment_ref)
        end
      end

      def get_leasehold_info(payment_ref:)
        with_core do |core|
          core.get_leasehold_info(payment_ref: payment_ref)
        end
      end

      private

      def with_core
        Hackney::UniversalHousing::Client.with_connection do |database|
          database.extension :identifier_mangling
          database.identifier_input_method = database.identifier_output_method = nil

          yield DatabaseBlock.new(database)
        end
      end

      class DatabaseBlock
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def get_tenancy_ref(payment_ref:)
          res = tenancy_agreement
                .where(u_saff_rentacc: payment_ref)
                .first

          raise TenancyNotFoundError unless res.present?
          { tenancy_ref: res[:tag_ref] }
        end

        def get_leasehold_info(payment_ref:)
          res = tenancy_agreement
                .select_append(Sequel.qualify(:MATenancyAgreement, :prop_ref).as(:tenancy_prop_ref))
                .select_append(Sequel.qualify(:MATenancyAgreement, :tenure).as(:tenure_type))
                .where(u_saff_rentacc: payment_ref)
                .exclude(Sequel.trim(Sequel.qualify(:MATenancyAgreement, :prop_ref)) => '')
                .join(rent, prop_ref: Sequel.qualify(:MATenancyAgreement, :prop_ref))
                .join(household, house_ref: Sequel.qualify(:MATenancyAgreement, :house_ref))
                .first

          raise TenancyNotFoundError unless res.present?

          prop_ref = res[:tenancy_prop_ref]

          property_res = property.first(prop_ref: prop_ref) || {}
          corr_address = get_correspondence_address(
            corr_postcode: res[:corr_postcode],
            prop_postcode: property_res[:post_code],
            household_res: res,
            property_res: property_res
          )

          {
            payment_ref: payment_ref,
            tenancy_ref: res[:tag_ref].strip,
            total_collectable_arrears_balance: res[:cur_bal],
            original_lease_date: res[:sc_leasedate],
            lessee_full_name: res[:house_desc]&.strip,
            lessee_short_name: res[:house_desc]&.strip,
            date_of_current_purchase_assignment: res[:cot],
            correspondence_address1: corr_address[:preamble]&.strip,
            correspondence_address2: "#{corr_address[:desig]&.strip} #{corr_address[:aline1]&.strip}",
            correspondence_address3: corr_address[:aline2]&.strip || '',
            correspondence_address4: corr_address[:aline3]&.strip || '',
            correspondence_address5: corr_address[:aline4]&.strip || '',
            correspondence_postcode: corr_address[:post_code]&.strip || '',
            property_address: "#{property_res[:address1]&.strip}, #{property_res[:post_code]&.strip}",
            international: international?(corr_address[:post_code]),
            money_judgement: res[:u_money_judgement],
            charging_order: res[:u_charging_order],
            bal_dispute: res[:u_bal_dispute],
            tenure_type: res[:tenure_type]
          }
        end

        private

        def tenancy_agreement
          @tenancy_agreement ||= database[:MATenancyAgreement]
        end

        def postcode
          @postcode ||= database[:UHPostCode]
        end

        def rent
          @rent ||= database[:UHRent]
        end

        def property
          @property ||= database[:MAProperty]
        end

        def household
          @household ||= database[:UHHousehold]
        end

        def get_correspondence_address(corr_postcode:, prop_postcode:, household_res:, property_res:)
          if corr_postcode.present?
            postcode.first(post_code: corr_postcode).presence&.merge(
              desig: household_res[:corr_desig],
              preamble: household_res[:corr_preamble]
            )
          elsif prop_postcode.present?
            postcode.first(post_code: prop_postcode).presence&.merge(
              desig: property_res[:post_desig],
              preamble: property_res[:post_preamble]
            )
          else
            {
              desig: household_res[:corr_desig],
              preamble: household_res[:corr_preamble]
            }
          end
        end

        def international?(postcode)
          postcode.nil? ? '' : !UKPostcode.parse(postcode).valid?
        end
      end
    end
    class TenancyNotFoundError < StandardError; end
  end
end
