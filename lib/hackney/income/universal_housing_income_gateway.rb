module Hackney
  module Income
    class UniversalHousingIncomeGateway
      def get_income_info(tenancy_ref:)
        with_core do |core|
          core.get_income_info(tenancy_ref: tenancy_ref)
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

        def get_income_info(tenancy_ref:)
          res = tenancy_agreement
                .exclude(Sequel.trim(Sequel.qualify(:prop_table, :prop_ref)) => '')
                .join(property, { prop_ref: Sequel.qualify(:tenagree, :prop_ref) }, table_alias: 'prop_table')
                .join(postcode, post_code: Sequel.qualify(:prop_table, :post_code))
                .join(member, house_ref: Sequel.qualify(:tenagree, :house_ref))
                .where(tag_ref: tenancy_ref)
                .first

          raise TenancyNotFoundError unless res.present?
          # correspondence_address1: corr_address[:preamble]&.strip,
          # correspondence_address2: "#{corr_address[:desig]&.strip} #{corr_address[:aline1]&.strip}",
          # correspondence_address3: corr_address[:aline2]&.strip || '',
          # correspondence_address4: corr_address[:aline3]&.strip || '',
          # correspondence_address5: corr_address[:aline4]&.strip || '',
          # correspondence_postcode: corr_address[:post_code]&.strip || '',
          # property_address: "#{property_res[:address1]&.strip}, #{property_res[:post_code]&.strip}",
          {
            title: res[:title]&.strip,
            forename: res[:forename]&.strip,
            surname: res[:surname]&.strip,
            address_preamble: res[:post_preamble]&.strip, # door number or address line 1
             #  true first line of address is post_desig + aline1
            address_name_number: res[:post_desig]&.strip, # to be added to a line1
            # address_line1: res[:aline1]&.strip,
            address_line1: res[:post_desig]&.strip + res[:aline1]&.strip,
            address_line2: res[:aline2]&.strip || '',
            address_line3: res[:aline3]&.strip || '',
            address_line4: res[:aline4]&.strip || '',
            address_post_code: res[:post_code]&.strip || '',
            property_ref: res[:prop_ref]&.strip,
            total_collectable_arrears_balance: res[:cur_bal],
            payment_ref: res[:u_saff_rentacc]&.strip || '',
            tenancy_ref: tenancy_ref
          }
        end

        private

        def tenancy_agreement
          @tenancy_agreement ||= database[:tenagree]
        end

        def postcode
          @postcode ||= database[:postcode]
        end

        def property
          @property ||= database[:property]
        end

        def member
          @member ||= database[:member]
        end
      end
    end
    class TenancyNotFoundError < StandardError; end
  end
end
