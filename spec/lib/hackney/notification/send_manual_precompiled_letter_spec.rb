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

  before do
    allow(add_action_diary_usecase).to receive(:execute)
  end

  context 'when sending an income collection letter' do
    let(:tenancy_ref) { Faker::Number.number(6) }
    let(:subject) do
      send_precompiled_letter.execute(
        payment_ref: nil,
        tenancy_ref: tenancy_ref,
        template_id: 'income_collection_letter_1',
        unique_reference: unique_reference,
        letter_pdf: test_file
      )
    end

    it 'will send the letter by without calling the leasehold gateway using a tenancy_ref' do
      expect_any_instance_of(leasehold_gateway).not_to receive(:get_tenancy_ref)
    end
  end

  context 'when sending a leasehold letter' do
    let(:payment_ref) { Faker::Number.number(6) }
    let(:subject) do
      send_precompiled_letter.execute(
        payment_ref: payment_ref,
        tenancy_ref: nil,
        template_id: 'letter_1_in_arrears_FH',
        unique_reference: unique_reference,
        letter_pdf: test_file
      )
    end

    before {
      allow_any_instance_of(leasehold_gateway).to receive(:get_tenancy_ref).and_return(tenancy_ref: Faker::Number.number(6))
    }

    it 'will send the letter by calling the leasehold gateway using a payment_ref' do
      expect_any_instance_of(leasehold_gateway).to receive(:get_tenancy_ref).with(payment_ref: payment_ref)
      expect(subject).to be_a Hackney::Notification::Domain::NotificationReceipt
      expect(subject.body).to include(unique_reference)
    end
  end
end
