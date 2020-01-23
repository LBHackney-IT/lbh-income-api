require 'rails_helper'

describe Hackney::Income::UniversalHousingTenanciesGateway, universal: true do
  let(:gateway) { described_class.new }

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
        expect(subject).to eq(['000001/01'])
      end
    end

    context 'with a tenancy ref that includes whitespace' do
      before { create_uh_tenancy_agreement(tenancy_ref: ' 000001/01 ', current_balance: 50.00) }

      it 'strips the whitespace' do
        expect(subject).to eq(['000001/01'])
      end
    end

    context 'when there are three tenancies in arrears, but only one is a master account' do
      before do
        create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 50.00, agreement_type: 'M')
        create_uh_tenancy_agreement(tenancy_ref: '000002/01', current_balance: 50.00, agreement_type: 'R')
        create_uh_tenancy_agreement(tenancy_ref: '000003/01', current_balance: 50.00, agreement_type: 'X')
      end

      it 'returns only the master account tenancy' do
        expect(subject).to eq(['000001/01'])
      end
    end

    context 'when there is one tenancy in arrears' do
      before do
        create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 50.00)
      end

      it 'returns that tenancy' do
        expect(subject).to eq(['000001/01'])
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
        expect(subject).to eq(['000001/01'])
      end
    end

    context 'when there is a tenancy in arrears which is NOT a Secure tenancy' do
      before { create_uh_tenancy_agreement(tenancy_ref: '000001/01', current_balance: 100.00, tenure_type: 'HEY') }

      it 'returns nothing' do
        expect(subject).to eq([])
      end
    end

    context 'when patches are restricted' do
      context 'when a list of acceptable patches is given' do
        let(:gateway) { described_class.new(restrict_patches: true, patches: %w[X01 Y01 Z01]) }

        context 'when a tenancy is not in an accepted patch' do
          before do
            create_uh_tenancy_agreement(tenancy_ref: '00001/01', current_balance: 10.0, prop_ref: 'PROP1')
            create_uh_property(property_ref: 'PROP1', patch_code: 'B01')
          end

          it 'does not return the tenancy' do
            expect(subject).to be_empty
          end
        end

        context 'when a tenancy is in one of the accepted patches' do
          before do
            create_uh_tenancy_agreement(tenancy_ref: '00001/01', current_balance: 10.0, prop_ref: 'PROP1')
            create_uh_property(property_ref: 'PROP1', patch_code: 'Z01')
          end

          it 'includes the tenancy' do
            expect(subject).to eq(%w[00001/01])
          end
        end

        context 'when a tenancy either has no patch or has an accepted patch' do
          before do
            create_uh_tenancy_agreement(tenancy_ref: '00001/01', current_balance: 10.0, prop_ref: 'PROP1')
            create_uh_property(property_ref: 'PROP1', patch_code: 'Z01')
            create_uh_tenancy_agreement(tenancy_ref: '00002/01', current_balance: 10.0, prop_ref: 'PROP2')
            create_uh_property(property_ref: 'PROP2', patch_code: nil)
          end

          it 'includes the tenancy' do
            expect(subject).to eq(%w[00001/01 00002/01])
          end
        end
      end

      context 'without being given a list of acceptable patches' do
        let(:gateway) { described_class.new(restrict_patches: true) }

        before do
          create_uh_tenancy_agreement(tenancy_ref: '00001/01', current_balance: 10.0, prop_ref: 'PROP1')
          create_uh_property(property_ref: 'PROP1', patch_code: 'B01')
        end

        it 'returns no tenancies' do
          expect(subject).to eq([])
        end
      end
    end
  end
end
