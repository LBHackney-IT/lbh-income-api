require 'rails_helper'

describe Hackney::Notification::SendManualPrecompiledLetter do
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:add_action_diary_usecase) { instance_double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:gateway) { Hackney::Income::UniversalHousingLeaseholdGateway }
  let(:send_precompiled_letter) do
    described_class.new(
      notification_gateway: notification_gateway,
      add_action_diary_usecase: add_action_diary_usecase
    )
  end

  let(:test_file) { File.open('spec/test_files/test_pdf.pdf', 'rb') }
  let(:unique_reference) { SecureRandom.uuid }
  let(:template_id) { 'Letter 1 in arrears FH' }
  let(:payment_ref) { 'payment_ref' }

  before do
    allow(add_action_diary_usecase).to receive(:execute)
  end

  context 'when sending an letters manually' do
    before {
      expect_any_instance_of(gateway).to receive(:map_tenancy_ref_to_payment_ref).and_return(tenancy_ref: 12_321)
    }

    let(:subject) do
      send_precompiled_letter.execute(
        unique_reference: unique_reference,
        letter_pdf: test_file,
        payment_ref: payment_ref,
        template_id: template_id
      )
    end

    it { expect(subject).to be_a Hackney::Notification::Domain::NotificationReceipt }
    it { expect(subject.body).to include(unique_reference) }
    ['Letter 1 in arrears FH', 'Letter 2 in arrears FH',
     'Letter 1 in arrears LH', 'Letter 2 in arrears LH',
     'Letter 1 in arrears SO', 'Letter 2 in arrears SO'].each do |template|
      it {
        expect(send_precompiled_letter.execute(
                 unique_reference: unique_reference,
                 letter_pdf: test_file,
                 payment_ref: payment_ref,
                 template_id: template
               )).to include(unique_reference)
      }
    end
  end
end
