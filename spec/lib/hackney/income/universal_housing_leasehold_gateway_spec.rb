require 'rails_helper'

describe Hackney::Income::UniversalHousingLeaseholdGateway, universal: true do
  let(:gateway) { described_class.new }

  let(:payment_ref) { Random.rand(100).to_s }
  let(:tenancy_ref) { Random.rand(100).to_s }
  let(:house_ref) { Random.rand(100).to_s }
  let(:corr_preamble) { '23' }
  let(:cur_bal) { Random.rand(100) }
  let(:corr_desig) { 'Some street' }
  let(:corr_address) {
    {
      aline1: Faker::Address.street_name,
      aline2: 'Address line 2',
      aline3: 'Address line 3',
      aline4: 'Address line 4',
      post_code: 'E8 1DY'
    }
  }

  let(:prop_address) {
    {
      address1: Faker::Address.street_name,
      post_code: Faker::Address.postcode
    }
  }

  let(:lessee_full_name) { 'Mr John Doe Smith' }

  let(:prop_post_code) { Faker::Address.postcode }
  let(:prop_ref) { Random.rand(100).to_s }
  let(:sc_leasedate) { Faker::Date.forward(10) }
  let(:commencement_of_tenancy) { Faker::Date.backward(10) }

  after { truncate_uh_tables }

  describe 'get_tenancy_ref returns a tenancy_ref in exchange for a payment_ref' do
    context 'when payment_ref does not exist' do
      it 'raises an exception' do
        expect { gateway.get_tenancy_ref(payment_ref: 123) }.to raise_exception(Hackney::Income::TenancyNotFoundError)
      end
    end
  end

  describe 'get_leasehold_info collects all the info to populate the letter' do
    context 'when payment_ref does not exist' do
      it 'raises an exception' do
        expect { gateway.get_leasehold_info(payment_ref: 123) }.to raise_exception(Hackney::Income::TenancyNotFoundError)
      end
    end

    context 'when payment_ref exists' do
      before do
        create_uh_tenancy_agreement(tenancy_ref: tenancy_ref, current_balance: cur_bal, u_saff_rentacc: payment_ref,
                                    house_ref: house_ref, prop_ref: prop_ref, cot: commencement_of_tenancy)
        create_uh_rent(sc_leasedate: sc_leasedate, prop_ref: prop_ref)
        create_uh_househ(house_ref: house_ref, prop_ref: prop_ref, house_desc: lessee_full_name,
                         corr_preamble: corr_preamble, corr_desig: corr_desig,
                         post_code: prop_address[:post_code], corr_postcode: corr_address[:post_code])
      end

      context 'when correspondence postcode and property address exist' do
        before do
          create_uh_postcode(corr_address)
          create_uh_property(prop_address.merge(property_ref: prop_ref))
        end

        it 'get the prop_ref' do
          result = gateway.get_leasehold_info(payment_ref: payment_ref)

          expect(result).to eq({
            payment_ref: payment_ref,
            tenancy_ref: tenancy_ref,
            total_collectable_arrears_balance: cur_bal,
            original_lease_date: sc_leasedate,
            lessee_full_name: lessee_full_name,
            lessee_short_name: lessee_full_name,
            date_of_current_purchase_assignment: commencement_of_tenancy
          }.merge(expected_correspondence_address)
           .merge(expected_property_address))
        end
      end

      context 'when correspondence postcode and property address does NOT exist' do
        it 'get the prop_ref' do
          result = gateway.get_leasehold_info(payment_ref: payment_ref)

          expect(result).to eq(
            payment_ref: payment_ref,
            tenancy_ref: tenancy_ref,
            total_collectable_arrears_balance: cur_bal,
            original_lease_date: sc_leasedate,
            lessee_full_name: lessee_full_name,
            lessee_short_name: lessee_full_name,
            date_of_current_purchase_assignment: commencement_of_tenancy,
            correspondence_address1: corr_preamble,
            correspondence_address2: corr_desig + ' ',
            correspondence_address3: '',
            correspondence_address4: '',
            correspondence_address5: '',
            correspondence_postcode: '',
            property_address: ', ',
            international: ''
          )
        end
      end
    end
  end

  def expected_correspondence_address
    {
      correspondence_address1: corr_preamble,
      correspondence_address2: corr_desig + ' ' + corr_address[:aline1],
      correspondence_address3: corr_address[:aline2],
      correspondence_address4: corr_address[:aline3],
      correspondence_address5: corr_address[:aline4],
      correspondence_postcode: corr_address[:post_code],
      international: false
    }
  end

  def expected_property_address
    {
      property_address: prop_address[:address1] + ', ' + prop_address[:post_code]
    }
  end
end
