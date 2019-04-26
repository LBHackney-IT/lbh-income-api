module Hackney
  module Income
    class UniversalHousingLeaseholdGateway
      def get_tenancy_ref(payment_ref:)
        res = tenancy_agreement
              .where(u_saff_rentacc: payment_ref)
              .first

        raise TenancyNotFoundError unless res.present?
        { tenancy_ref: res[:tag_ref] }
      end

      def get_leasehold_info(payment_ref:)
        res = tenancy_agreement
              .where(u_saff_rentacc: payment_ref)
              .exclude(Sequel.trim(Sequel.qualify(:tenagree, :prop_ref)) => '')
              .join(rent, prop_ref: :prop_ref)
              .join(household, prop_ref: :prop_ref)
              .first

        raise TenancyNotFoundError unless res.present?

        prop_ref = res[:prop_ref]

        corr_postcode_res = postcode.first(post_code: res[:corr_postcode]) || {}
        property_res = property.first(prop_ref: prop_ref) || {}

        {
          payment_ref: payment_ref,
          tenancy_ref: res[:tag_ref],
          total_collectable_arrears_balance: res[:cur_bal],
          original_lease_date: res[:sc_leasedate],
          lessee_full_name: res[:house_desc],
          lessee_short_name: res[:house_desc],
          date_of_current_purchase_assignment: res[:cot],
          correspondence_address1: res[:corr_preamble],
          correspondence_address2: "#{res[:corr_desig]} #{corr_postcode_res[:aline1]}",
          correspondence_address3: corr_postcode_res[:aline2] || '',
          correspondence_address4: corr_postcode_res[:aline3] || '',
          correspondence_address5: corr_postcode_res[:aline4] || '',
          correspondence_postcode: corr_postcode_res[:post_code] || '',
          property_address: "#{property_res[:address1]}, #{property_res[:post_code]}",
          international: international?(corr_postcode_res[:post_code])
        }
      end

      private

      def tenancy_agreement
        @tenancy_agreement ||= database[:tenagree]
      end

      def postcode
        @postcode ||= database[:postcode]
      end

      def rent
        @rent ||= database[:rent]
      end

      def property
        @property ||= database[:property]
      end

      def household
        @household ||= database[:househ]
      end

      def international?(postcode)
        postcode.nil? ? '' : !UKPostcode.parse(postcode).valid?
      end

      def database
        Hackney::UniversalHousing::Client.connection.tap do |db|
          db.extension :identifier_mangling
          db.identifier_input_method = db.identifier_output_method = nil
        end
      end
    end

    class TenancyNotFoundError < StandardError; end
  end
end
