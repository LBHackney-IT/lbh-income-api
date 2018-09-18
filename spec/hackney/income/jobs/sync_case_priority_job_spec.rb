require 'rails_helper'

describe Hackney::Income::Jobs::SyncCasePriorityJob do
  let(:tenancy_ref) { Faker::IDNumber.valid }
  subject { described_class }

  it 'should run the SyncCasePriority use case' do
    expect_any_instance_of(Hackney::Income::SyncCasePriority).to receive(:execute).with(tenancy_ref: tenancy_ref)
    subject.perform_now(tenancy_ref: tenancy_ref)
  end

  it 'should be able to be scheduled' do
    expect {
      subject.set(wait_until: Time.now + 5.minutes).perform_later
    }.to_not raise_error
  end
end
