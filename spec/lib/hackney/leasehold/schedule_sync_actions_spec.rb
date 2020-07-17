require 'rails_helper'

# TODO: RENAME from ScheduleSyncCases to descriptive schedule and delete
describe Hackney::Leasehold::ScheduleSyncActions do
  subject { sync_cases.execute }

  let(:universal_housing_gateway) { instance_double(Hackney::Leasehold::UniversalHousingGateway) }
  let(:background_job_gateway) { instance_double(Hackney::Income::BackgroundJobGateway) }
  let!(:removed_case_priority) { create(:case_priority) }

  let(:sync_cases) do
    described_class.new(
      universal_housing_gateway: universal_housing_gateway,
      background_job_gateway: background_job_gateway
    )
  end

  context 'when there are priorities that are no longer in arrears' do
    let(:case_priorities) { create_list(:case_priority, 2) }
    let(:tenancy_refs) { [case_priorities.first.tenancy_ref, attributes_for(:case_priority)[:tenancy_ref]] }

    it 'deletes non priority cases them from the database' do

      sync_cases.send(:delete_case_priorities_not_syncable, case_priorities: case_priorities, tenancy_refs: tenancy_refs)
      found = Hackney::IncomeCollection::Action.where(tenancy_ref: case_priorities.pluck(:tenancy_ref))
      expect(found).to include(case_priorities.first)
      expect(found).not_to include(case_priorities.last)
    end
  end

  context 'when syncing cases' do
    context 'without finding any cases' do
      it 'queues no jobs' do
        expect(universal_housing_gateway).to receive(:tenancies_in_arrears).and_return([]).once
        expect(background_job_gateway).not_to receive(:schedule_case_priority_sync)
        subject
      end
    end

    context 'when finding cases that are not to be synced' do
      it 'deletes those case_priorities' do
        expect(universal_housing_gateway).to receive(:tenancies_in_arrears).and_return([]).once
        expect_any_instance_of(described_class).to receive(:delete_case_priorities_not_syncable)
          .with(case_priorities: [removed_case_priority], tenancy_refs: [])

        subject
      end
    end

    context 'when finding a case' do
      let(:tenancy_ref) { Faker::IDNumber.valid }
      let(:universal_housing_gateway) { double(tenancies_in_arrears: [tenancy_ref]) }

      it 'queues a job to sync that case' do
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: tenancy_ref)
        subject
      end
    end

    context 'when 3 cases are found' do
      let(:universal_housing_gateway) do
        double(tenancies_in_arrears: ['000010/01', '000011/01', '000012/01'])
      end

      it 'queues a job for each case individually' do
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: '000010/01')
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: '000011/01')
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: '000012/01')

        subject
      end
    end
  end
end
