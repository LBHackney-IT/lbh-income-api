require 'rails_helper'

describe Hackney::Income::Jobs::SyncCasePriorityJob do
  subject { described_class }

  let(:tenancy_ref) { Faker::IDNumber.valid }

  context 'when sync jobs are disabled' do
    before do
      allow_any_instance_of(described_class)
        .to receive(:run_tenancy_sync_jobs?)
        .and_return(false)
    end

    it 'does not run use case' do
      expect_any_instance_of(Hackney::Income::SyncCasePriority).not_to receive(:execute)
      subject.perform_now(tenancy_ref: tenancy_ref)
    end
  end

  context 'when sync jobs are enabled' do
    before do
      allow_any_instance_of(described_class)
        .to receive(:run_tenancy_sync_jobs?)
        .and_return(true)
    end

    it 'runs the SyncCasePriority use case' do
      expect_any_instance_of(Hackney::Income::SyncCasePriority)
        .to receive(:execute)
        .with(tenancy_ref: tenancy_ref)

      subject.perform_now(tenancy_ref: tenancy_ref)
    end

    it 'is able to be scheduled' do
      expect do
        subject.set(wait_until: Time.now + 5.minutes).perform_later
      end.not_to raise_error
    end
  end
end
