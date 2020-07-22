require 'rails_helper'

require 'sidekiq/testing'

describe Hackney::Income::BackgroundJobGateway do
  context 'when scheduling a job to sync priority for a case' do
    subject { described_class.new.schedule_case_priority_sync(tenancy_ref: tenancy_ref) }

    let(:tenancy_ref) { Faker::IDNumber.valid }

    context 'when scheduling rents' do
      it 'enqueues the job to run as soon as possible with leasehold variable as false' do
        expect { subject }.to have_enqueued_job(Hackney::Income::Jobs::SyncCasePriorityJob).with(
          tenancy_ref: tenancy_ref, leasehold: false
        )
      end
    end

    context 'when scheduling leasehold' do
      subject { described_class.new.schedule_case_priority_sync(tenancy_ref: tenancy_ref, leasehold: true) }

      it 'enqueues the job to run as soon as possible' do
        expect { subject }.to have_enqueued_job(Hackney::Income::Jobs::SyncCasePriorityJob).with(
          tenancy_ref: tenancy_ref, leasehold: true
        )
      end
    end
  end

  context 'when scheduling a job to schedule_send_sms' do
    subject { described_class.new.schedule_send_sms_msg(case_id: case_id) }

    let(:case_id) { Faker::IDNumber.valid }

    it 'enqueues the job to run as soon as possible' do
      expect { subject }.to have_enqueued_job(Hackney::Income::Jobs::SendSMSJob).with(case_id: case_id)
    end
  end

  context 'when scheduling a job to sync priority for a case' do
    subject {
      described_class.new.add_action_diary_entry(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username
      )
    }

    let(:tenancy_ref) { Faker::IDNumber.valid }
    let(:action_code) { Faker::Internet.slug }
    let(:comment) { Faker::Lorem.paragraph }
    let(:username) { Faker::Name.name }

    it 'enqueues the job to run as soon as possible' do
      expect { subject }.to have_enqueued_job(Hackney::Income::Jobs::AddActionDiaryEntryJob).with(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment,
        username: username
      )
    end
  end
end
