require 'rails_helper'

describe Hackney::Notification::SendManualPrecompiledLetter do
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:add_action_diary_usecase) { instance_double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:leasehold_gateway) { Hackney::Income::UniversalHousingLeaseholdGateway }

  let(:send_precompiled_letter) do
    described_class.new(
      notification_gateway: notification_gateway,
      add_action_diary_usecase: add_action_diary_usecase,
      leasehold_gateway: leasehold_gateway.new
    )
  end

  let(:test_file) { File.open('spec/test_files/test_pdf.pdf', 'rb') }
  let(:unique_reference) { SecureRandom.uuid }
  let(:payment_ref) { 'payment_ref' }
  let(:tenancy_ref) { '12234' }

  before do
    allow(add_action_diary_usecase).to receive(:execute)
  end

  context 'when sending an automated income collection letter' do
    let(:subject) do
      send_precompiled_letter.execute(
        payment_ref: payment_ref,
        tenancy_ref: tenancy_ref,
        template_id: 'income collection letter',
        unique_reference: unique_reference,
        letter_pdf: test_file
      )
    end

    it 'will not call the leasehold_gatway' do
      expect_any_instance_of(leasehold_gateway).not_to receive(:get_tenancy_ref)
    end
  end

  context 'when sending an letters manually' do
    let(:template_id) { 'Letter 1 in arrears FH' }

    let(:subject) do
      send_precompiled_letter.execute(
        unique_reference: unique_reference,
        letter_pdf: test_file,
        payment_ref: payment_ref,
        tenancy_ref: nil,
        template_id: template_id
      )
    end

    before {
      expect_any_instance_of(leasehold_gateway).to receive(:get_tenancy_ref).and_return(tenancy_ref: 12_321)
    }

    it { expect(subject).to be_a Hackney::Notification::Domain::NotificationReceipt }
    it { expect(subject.body).to include(unique_reference) }

    context 'when templates write into action diary they should have action codes associated with them' do
      [
        'letter 1 in arrears FH', 'letter 1 in arrears LH',
        'letter 1 in arrears SO', 'letter 2 in arrears FH',
        'letter 2 in arrears LH', 'letter 2 in arrears SO',
        'income collection letter 1', 'income collection letter 2'
      ].each do |template|
        it {
          expect {
            send_precompiled_letter.execute(
              unique_reference: unique_reference,
              letter_pdf: test_file,
              payment_ref: payment_ref,
              tenancy_ref: nil,
              template_id: template
            )
          } .not_to raise_error
        }
      end
    end
  end
end
