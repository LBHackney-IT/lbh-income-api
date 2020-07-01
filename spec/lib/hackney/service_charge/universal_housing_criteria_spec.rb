require 'rails_helper'

describe Hackney::ServiceCharge::UniversalHousingCriteria, universal: true do
  subject(:criteria) { described_class.for_lease(universal_housing_client, tenancy_ref) }

  context 'when there is a tenancy agreement' do
    let(:universal_housing_client) { Hackney::UniversalHousing::Client.connection }

    let(:tenancy_ref) { '000015/01' }

    let(:current_balance) { Faker::Number.decimal.to_f }

    let(:payment_ref) { Faker::Number.number(digits: 10).to_s }

    let(:house_ref) { Faker::Number.number(digits: 6).to_s }

    let(:property_ref) { Faker::Number.number(digits: 8).to_s }

    before {
      create_uh_tenancy_agreement(
        tenancy_ref: tenancy_ref,
        current_balance: current_balance,
        u_saff_rentacc: payment_ref,
        house_ref: house_ref,
        prop_ref: property_ref
      )
    }

    it { is_expected.to be_instance_of(described_class) }

    describe '#balance' do
      subject { criteria.balance }

      it 'returns the current balance of a tenancy' do
        expect(subject).to eq(current_balance)
      end
    end

    describe '#payment_ref' do
      subject { criteria.payment_ref }

      it 'returns the current payment ref of a tenancy' do
        expect(subject).to eq(payment_ref)
      end
    end

    describe '#latest_letter' do
      subject { criteria.latest_letter }

      context 'when the tenant has not been sent a letter' do
        it { is_expected.to be_nil }
      end

      context 'when letters have been sent the tenant' do
        let(:newer_letter_code) { Hackney::Tenancy::ActionCodes::FOR_UH_LEASEHOLD_SQL.sample }
        let(:older_letter_code) { Hackney::Tenancy::ActionCodes::FOR_UH_LEASEHOLD_SQL.sample }

        before {
          create_uh_action(tenancy_ref: tenancy_ref, code: newer_letter_code, date: Date.today)
          create_uh_action(tenancy_ref: tenancy_ref, code: older_letter_code, date: Date.today - 2.days)
        }

        it 'return the latest communication code' do
          expect(subject).to eq(newer_letter_code)
        end
      end

      context 'when an action code is not a letter action code' do
        before {
          create_uh_action(tenancy_ref: tenancy_ref, code: 'RBA', date: Date.today)
        }

        it { is_expected.to be_nil }
      end
    end

    describe '#latest_letter_date' do
      subject { criteria.latest_letter_date }

      context 'when the tenant has not been contacted' do
        it { is_expected.to be_nil }
      end

      context 'when in communication with the tenant' do
        let(:letter_code) { Hackney::Tenancy::ActionCodes::FOR_UH_LEASEHOLD_SQL.sample }

        before {
          create_uh_action(tenancy_ref: tenancy_ref, code: letter_code, date: Date.yesterday)
          create_uh_action(tenancy_ref: tenancy_ref, code: letter_code, date: Date.today)
        }

        it 'return the latest letter date' do
          expect(subject).to eq(Date.today)
        end
      end
    end

    describe '#lessee' do
      subject { criteria.lessee }

      context 'when in communication with the tenant' do
        let(:lessee_name) { Faker::Games::LeagueOfLegends.champion }

        before {
          create_uh_househ(house_ref: house_ref, house_desc: lessee_name)
        }

        it 'return the lessee' do
          expect(subject).to eq(lessee_name)
        end
      end
    end

    describe '#direct_debit_status' do
      subject { criteria.direct_debit_status }

      before {
        create_uh_direct_debit(tenancy_ref: tenancy_ref, lu_desc: status)
      }

      let(:status) { Faker::Games::LeagueOfLegends.summoner_spell }

      context 'when in communication with the tenant' do
        it 'return the direct debit status' do
          expect(subject).to eq(status)
        end
      end

      context 'when there is more than one direct debit' do
        before {
          create_uh_direct_debit(tenancy_ref: tenancy_ref, ddagree_status: 123, ddstart: '2020-06-30 00:00:00', lu_desc: new_status)
        }

        let(:new_status) { Faker::Games::LeagueOfLegends.champion }

        it 'returns the latest direct debit status' do
          expect(subject).to eq(new_status)
        end
      end
    end

    describe '#property_address' do
      subject { criteria.property_address }

      let(:address1) { Faker::Address.street_address }
      let(:post_code) { Faker::Address.postcode }

      before do
        create_uh_property(property_ref: property_ref, address1: address1, post_code: post_code)
      end

      it 'returns a nicely formatted address' do
        expect(subject).to eq("#{address1}, London, #{post_code}")
      end
    end

    describe '#patch_code' do
      context 'with an existing property reference' do
        before do
          create_uh_property(property_ref: property_ref, patch_code: patch_code)
        end

        context 'with a patch code' do
          let(:patch_code) { 'E01' }

          it 'contains the correct patch code' do
            expect(criteria.patch_code).to eq(patch_code)
          end
        end

        context 'without a patch code' do
          let(:patch_code) { nil }

          it 'is nil' do
            expect(criteria.patch_code).to be_nil
          end
        end
      end

      context "with a property reference that doesn't resolve" do
        it 'is nil' do
          expect(criteria.patch_code).to be_nil
        end
      end
    end

    it 'has the same instance methods as the stub' do
      expect(criteria.methods).to match_array(Stubs::StubServiceChargeCriteria.new.methods)
    end
  end

  describe '#format_letter_action_codes_for_sql' do
    let(:code_one) { 'AC' }
    let(:code_two) { 'DC' }
    let(:stubbed_codes) { [code_one, code_two] }

    it 'formats the list of codes' do
      stub_const('Hackney::Tenancy::ActionCodes::FOR_UH_LEASEHOLD_SQL', stubbed_codes)

      expect(described_class.format_letter_action_codes_for_sql).to eq("('#{code_one}'), ('#{code_two}')")
    end
  end

  describe '#build_sql' do
    let(:dummy_string) { "('SOME_STRING')" }

    it 'contains a correct list of Actions Codes' do
      expect(described_class).to receive(:format_letter_action_codes_for_sql).and_return(dummy_string)

      expect(described_class.build_sql).to include(dummy_string)
    end
  end
end
