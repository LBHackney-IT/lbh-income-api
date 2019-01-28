require 'rails_helper'

describe Hackney::Income::BackgroundJobGateway do
  before { ActiveJob::Base.queue_adapter = :test }

  context 'when scheduling a job to sync priority for a case' do
    subject { described_class.new.schedule_case_priority_sync(tenancy_ref: tenancy_ref) }

    let(:tenancy_ref) { Faker::IDNumber.valid }

    it 'enqueues the job to run as soon as possible' do
      expect { subject }.to have_enqueued_job(Hackney::Income::Jobs::SyncCasePriorityJob).with(
        tenancy_ref: tenancy_ref
      )
    end
  end

  context 'when scheduling a job to schedule_send_green_in_arrears_msg' do
    subject { described_class.new.schedule_send_green_in_arrears_msg(case_id: case_id) }

    let(:case_id) { Faker::IDNumber.valid }

    it 'enqueues the job to run as soon as possible' do
      expect { subject }.to have_enqueued_job(Hackney::Income::Jobs::SendGreenInArrearsMsgJob).with(case_id: case_id)
    end
  end

  context 'when scheduling a job to sync priority for a case' do
    subject { described_class.new.add_action_diary_entry(tenancy_ref: tenancy_ref, action_code: action_code, comment: comment) }

    let(:tenancy_ref) { Faker::IDNumber.valid }
    let(:action_code) { Faker::Internet.slug }
    let(:comment) { Faker::Lorem.paragraph }

    it 'enqueues the job to run as soon as possible' do
      expect { subject }.to have_enqueued_job(Hackney::Income::Jobs::AddActionDiaryEntryJob).with(
        tenancy_ref: tenancy_ref,
        action_code: action_code,
        comment: comment
      )
    end
  end
end
