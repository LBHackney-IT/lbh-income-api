require 'rails_helper'

describe Hackney::Leasehold::UniversalHousingGateway, universal: true do
  let(:gateway) { described_class.new }

  context 'when testing #lease_in_arrears' do
    context 'when retrieving tenancy refs for cases in arrears' do
      subject { gateway.tenancy_refs_in_arrears }

      let(:lease_rent_group) { 'LSC' }

      context 'when there are no tenancies' do
        it 'returns none' do
          expect(subject).to be_empty
        end
      end

      context 'when there is one tenancy in arrears and in the leasehold rent group' do
        before { create_uh_tenancy_agreement(tenancy_ref: '000001/01   ', current_balance: 50.00, rentgrp_ref: lease_rent_group) }

        it 'returns that tenancy with stripped whitespace' do
          expect(subject).to eq(['000001/01'])
        end
      end

      context 'when there are three tenancies in arrears, but only one is in the leasehold rent group' do
        before do
          create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 50.00, rentgrp_ref: lease_rent_group)
          create_uh_tenancy_agreement(tenancy_ref: '000002/01', current_balance: 50.00)
          create_uh_tenancy_agreement(tenancy_ref: '000003/01', current_balance: 50.00)
        end

        it 'returns only the one in lease rent group' do
          expect(subject).to eq(['000001/01'])
        end
      end

      context 'when there is one tenancy in the leasehold rent group and in credit' do
        before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: -50.00, rentgrp_ref: lease_rent_group) }

        it 'returns nothing' do
          expect(subject).to eq([])
        end
      end

      context 'when there are two tenancies in arrears and two in credit and all are in the rent group' do
        before do
          create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: -100.00, rentgrp_ref: lease_rent_group)
          create_uh_tenancy_agreement(tenancy_ref: '000002/01', current_balance: 50.00, rentgrp_ref: lease_rent_group)
          create_uh_tenancy_agreement(tenancy_ref: '000003/01', current_balance: -75.00, rentgrp_ref: lease_rent_group)
          create_uh_tenancy_agreement(tenancy_ref: '000004/01', current_balance: 100.00, rentgrp_ref: lease_rent_group)
        end

        it 'returns the two in arrears' do
          expect(subject).to eq(%w[000002/01 000004/01])
        end
      end

      context 'when there is a tenancy in arrears which has been terminated in the rent group' do
        before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 100.00, terminated: true, rentgrp_ref: lease_rent_group) }

        it 'returns nothing' do
          expect(subject).to eq([])
        end
      end

      context 'when there are three tenancies in arrears, but only one is a master account' do
        before do
          create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 50.00, agreement_type: 'M', rentgrp_ref: lease_rent_group)
          create_uh_tenancy_agreement(tenancy_ref: '000002/01', current_balance: 50.00, agreement_type: 'R', rentgrp_ref: lease_rent_group)
          create_uh_tenancy_agreement(tenancy_ref: '000003/01', current_balance: 50.00, agreement_type: 'X', rentgrp_ref: lease_rent_group)
        end

        it 'returns only the master account tenancy' do
          expect(subject).to eq(['000001/01'])
        end
      end

      context 'when there is a tenancy in arrears which is a freehold tenure tenancy' do
        before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 100.00, tenure_type: 'FRE', rentgrp_ref: lease_rent_group) }

        it 'does not return the tenancy' do
          expect(subject).to eq([])
        end
      end
    end
  end
end
