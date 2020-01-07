require 'rails_helper'

describe Hackney::Income::UniversalHousingIncomeGateway, universal: true do
  let(:gateway) { described_class.new }

  let(:payment_ref) { Random.rand(100).to_s }
  let(:tenancy_ref) { Random.rand(100).to_s }
  let(:house_ref) { Random.rand(100).to_s }
  let(:cur_bal) { Random.rand(100) }
  let(:property_postcode) { Faker::Address.postcode }
  let(:prop_preamble) { Faker::Address.secondary_address }
  let(:prop_desig) { Random.rand(100).to_s }
  let(:first_name) { Faker::Name.first_name }
  let(:last_name) { Faker::Name.last_name }
  let(:prefix) { Faker::Name.prefix }
  let(:property_address) {
    {
      aline1: Faker::Address.street_name,
      aline2: Faker::Address.community,
      aline3: Faker::Address.city,
      post_code: property_postcode
    }
  }

  let(:prop_address) {
    {
      address1: Faker::Address.street_name,
      post_code: property_postcode,
      post_preamble: prop_preamble,
      post_desig: prop_desig
    }
  }

  let(:prop_ref) { Random.rand(100).to_s }

  after { truncate_uh_tables }

  describe 'get_income_info collects all the info to populate the letter' do
    context 'when payment_ref does not exist' do
      it 'raises an exception' do
        expect { gateway.get_income_info(tenancy_ref: 123) }.to raise_exception(Hackney::Income::TenancyNotFoundError)
      end
    end

    context 'when tenancy_ref exists' do
      let(:set_household_postcode) { household_postcode }
      let(:create_property) { true }

      before do
        create_uh_property(prop_address.merge(property_ref: prop_ref)) if create_property
        create_uh_postcode(property_address)
        create_uh_househ(house_ref: house_ref, prop_ref: prop_ref)
        create_uh_tenancy_agreement(
          tenancy_ref: tenancy_ref, u_saff_rentacc: payment_ref,
          prop_ref: prop_ref, house_ref: house_ref, current_balance: cur_bal
        )

        create_uh_member(
          house_ref: house_ref,
          title: prefix,
          forename: first_name,
          surname: last_name
        )
      end

      it 'all relevant info is found' do
        result = gateway.get_income_info(tenancy_ref: tenancy_ref)

        expect(result).to include(
          tenancy_ref: tenancy_ref,
          forename: first_name,
          surname: last_name,
          address_line1: prop_preamble,
          address_line2: prop_desig + ' ' + property_address[:aline1],
          address_line3: property_address[:aline2],
          address_line4: property_address[:aline3],
          address_post_code: property_address[:post_code]
        )
      end

      context 'when post_preamble is not present' do
        let(:prop_preamble) { '' }

        it 'the address is ordered correctly' do
          result = gateway.get_income_info(tenancy_ref: tenancy_ref)

          expect(result).to include(
            address_line1: prop_desig + ' ' + property_address[:aline1],
            address_line2: property_address[:aline2],
            address_line3: property_address[:aline3],
            address_post_code: property_address[:post_code]
          )
        end
      end
    end
  end
end
