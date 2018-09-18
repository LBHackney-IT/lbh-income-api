require 'rails_helper'

describe Hackney::Income::BackgroundJobGateway do
  before { ActiveJob::Base.queue_adapter = :test }

  context 'when scheduling a job to sync priority for a case' do
    let(:tenancy_ref) { Faker::IDNumber.valid }
    subject { described_class.new.schedule_case_priority_sync(tenancy_ref: tenancy_ref) }

    it 'should enqueue the job to run as soon as possible' do
      expect { subject }.to have_enqueued_job(Hackney::Income::Jobs::SyncCasePriorityJob)
        .with(tenancy_ref: tenancy_ref)
    end
  end
end
