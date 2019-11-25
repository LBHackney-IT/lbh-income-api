require 'rails_helper'

describe Hackney::Income::UniversalHousingTenanciesGateway, universal: true do
  let(:gateway) { described_class.new }

  after { truncate_uh_tables }

  context 'when retrieving tenancy refs for cases in arrears' do
    subject { gateway.tenancies_in_arrears }

    context 'when there are no tenancies' do
      it 'returns none' do
        expect(subject).to be_empty
      end
    end

    context 'when there is one tenancy in arrears' do
      before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 50.00) }

      it 'returns that tenancy' do
        expect(subject).to eq(%w[000001/01])
      end
    end

    context 'when there is one tenancy in credit' do
      before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: -50.00) }

      it 'returns nothing' do
        expect(subject).to eq([])
      end
    end

    context 'when there are two tenancies in arrears and two in credit' do
      before do
        create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: -100.00)
        create_uh_tenancy_agreement(tenancy_ref: '000002/01', current_balance: 50.00)
        create_uh_tenancy_agreement(tenancy_ref: '000003/01', current_balance: -75.00)
        create_uh_tenancy_agreement(tenancy_ref: '000004/01', current_balance: 100.00)
      end

      it 'returns the two in arrears' do
        expect(subject).to eq(%w[000002/01 000004/01])
      end
    end

    context 'when there is a tenancy in arrears which has been terminated' do
      before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 100.00, terminated: true) }

      it 'returns nothing' do
        expect(subject).to eq([])
      end
    end

    context 'when there is a tenancy in arrears which is a Secure tenancy' do
      before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 100.00, tenure_type: 'SEC') }

      it 'returns the tenancy' do
        expect(subject).to eq(%w[000001/01])
      end
    end

    context 'when there is a tenancy in arrears which is NOT a Secure tenancy' do
      before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 100.00, tenure_type: 'HEY') }

      it 'returns nothing' do
        expect(subject).to eq([])
      end
    end
  end
end
