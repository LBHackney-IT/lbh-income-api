require_relative '../../../../lib/hackney/income/dangerous_sync_cases'

describe Hackney::Income::DangerousSyncCases do
  let(:uh_tenancies_gateway) { double(tenancies_in_arrears: []) }
  let(:background_job_gateway) { double(schedule_case_priority_sync: nil) }

  let(:sync_cases) do
    described_class.new(
      uh_tenancies_gateway: uh_tenancies_gateway,
      background_job_gateway: background_job_gateway
    )
  end

  subject { sync_cases.execute }

  context 'when syncing cases' do
    context 'and finding no cases' do
      it 'should queue no jobs' do
        expect(background_job_gateway).not_to receive(:schedule_case_priority_sync)
        subject
      end
    end

    context 'and finding a case' do
      let(:tenancy_ref) { Faker::IDNumber.valid }
      let(:uh_tenancies_gateway) { double(tenancies_in_arrears: [tenancy_ref]) }

      it 'should queue a job to sync that case' do
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: tenancy_ref)
        subject
      end
    end

    context 'and finding a few cases' do
      let(:uh_tenancies_gateway) do
        double(tenancies_in_arrears: ['000010/01', '000011/01', '000012/01'])
      end

      it 'should queue a job for each case individually' do
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: '000010/01')
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: '000011/01')
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: '000012/01')

        subject
      end
    end
  end
end
