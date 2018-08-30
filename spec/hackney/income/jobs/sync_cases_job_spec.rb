require 'rails_helper'

describe Hackney::Income::Jobs::SyncCasesJob do
  subject { described_class }

  it 'should run the DangerousSyncCases use case' do
    expect_any_instance_of(Hackney::Income::DangerousSyncCases).to receive(:execute).with(no_args)
    subject.perform_now
  end

  it 'should be able to be scheduled' do
    expect {
      subject.set(wait_until: Time.now + 5.minutes).perform_later
    }.to_not raise_error
  end

  it 'should still schedule a new job for tomorrow on completion' do
    subject.perform_now
    expect(Delayed::Job.last).to have_attributes(run_at: next_expected_run_time)
  end

  context 'when the DangerousSyncCases use case fails' do
    before do
      allow_any_instance_of(Hackney::Income::DangerousSyncCases).to receive(:execute).and_raise('oh no!')
      subject.perform_later
    end

    it 'the job should still succeed and be removed from the queue' do
      job = Delayed::Job.first

      expect {
        Delayed::Worker.new.work_off
      }.to change {
        Delayed::Job.exists?(job.id)
      }.from(true).to(false)
    end

    it 'should still schedule a new job for tomorrow' do
      Delayed::Worker.new.work_off

      expect(Delayed::Job.last).to have_attributes(run_at: next_expected_run_time)
    end
  end

  def next_expected_run_time
    Date.tomorrow.midnight + 3.hours
  end
end
