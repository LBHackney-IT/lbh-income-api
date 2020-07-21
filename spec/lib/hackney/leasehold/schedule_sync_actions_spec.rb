require 'rails_helper'

describe Hackney::Leasehold::ScheduleSyncActions do
  subject { sync_cases.execute }

  let(:universal_housing_gateway) { instance_double(Hackney::Leasehold::UniversalHousingGateway) }
  let(:background_job_gateway) { instance_double(Hackney::Leasehold::BackgroundJobGateway) }
  let!(:removed_action) { create(:leasehold_action) }

  let(:sync_cases) do
    described_class.new(
      universal_housing_gateway: universal_housing_gateway,
      background_job_gateway: background_job_gateway
    )
  end

  context 'when there are actions that are no longer in arrears' do
    let(:leasehold_actions) { create_list(:leasehold_action, 2) }
    let(:tenancy_refs) { [leasehold_actions.first.tenancy_ref, attributes_for(:leasehold_action)[:tenancy_ref]] }

    it 'deletes actions no longer in arrears from the database' do
      sync_cases.send(:delete_actions_not_syncable, actions: leasehold_actions, tenancy_refs: tenancy_refs)
      found = Hackney::IncomeCollection::Action.where(tenancy_ref: leasehold_actions.pluck(:tenancy_ref))
      expect(found).to include(leasehold_actions.first)
      expect(found).not_to include(leasehold_actions.last)
    end
  end

  context 'when syncing cases' do
    context 'without finding any cases' do
      it 'queues no jobs' do
        expect(universal_housing_gateway).to receive(:tenancy_refs_in_arrears).and_return([]).once
        expect(background_job_gateway).not_to receive(:schedule_case_priority_sync)
        subject
      end
    end

    context 'when finding cases that are not to be synced' do
      it 'deletes those case_priorities' do
        expect(universal_housing_gateway).to receive(:tenancy_refs_in_arrears).and_return([]).once
        expect_any_instance_of(described_class).to receive(:delete_actions_not_syncable)
          .with(actions: [removed_action], tenancy_refs: [])

        subject
      end
    end

    context 'when finding a case' do
      let(:tenancy_ref) { Faker::IDNumber.valid }
      let(:universal_housing_gateway) { double(tenancy_refs_in_arrears: [tenancy_ref]) }

      it 'queues a job to sync that case' do
        expect(background_job_gateway).to receive(:schedule_case_priority_sync).with(tenancy_ref: tenancy_ref)
        subject
      end
    end

    context 'when 3 cases are found' do
      let(:universal_housing_gateway) do
        double(tenancy_refs_in_arrears: ['000010/01', '000011/01', '000012/01'])
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
