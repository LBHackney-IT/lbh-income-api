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

        corr_address = get_correspondence_address(corr_postcode: res[:corr_postcode], prop_postcode: res[:post_code])
        property_res = property.first(prop_ref: prop_ref) || {}

        {
          payment_ref: payment_ref,
          tenancy_ref: res[:tag_ref].strip,
          total_collectable_arrears_balance: res[:cur_bal],
          original_lease_date: res[:sc_leasedate],
          lessee_full_name: res[:house_desc]&.strip,
          lessee_short_name: res[:house_desc]&.strip,
          date_of_current_purchase_assignment: res[:cot],
          correspondence_address1: res[:corr_preamble]&.strip,
          correspondence_address2: "#{res[:corr_desig]&.strip} #{corr_address[:aline1]&.strip}",
          correspondence_address3: corr_address[:aline2]&.strip || '',
          correspondence_address4: corr_address[:aline3]&.strip || '',
          correspondence_address5: corr_address[:aline4]&.strip || '',
          correspondence_postcode: corr_address[:post_code]&.strip || '',
          property_address: "#{property_res[:address1]&.strip}, #{property_res[:post_code]&.strip}",
          international: international?(corr_address[:post_code])
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

      def get_correspondence_address(corr_postcode:, prop_postcode:)
        address = if corr_postcode.present? # we use the correspondence address
                    postcode.first(post_code: corr_postcode)
                  elsif prop_postcode.present? # we use the property address
                    postcode.first(post_code: prop_postcode)
                  end
        address || {}
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
