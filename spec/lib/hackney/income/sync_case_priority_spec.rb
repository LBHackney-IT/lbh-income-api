require 'rails_helper'

describe Hackney::Income::SyncCasePriority do
  subject { sync_case.execute(tenancy_ref: tenancy_ref) }

  let(:stub_tenancy_object) { double }
  let(:stored_tenancies_gateway) { double(store_tenancy: stub_tenancy_object) }
  let(:criteria) { Stubs::StubCriteria.new }
  let(:weightings) { Hackney::Income::TenancyPrioritiser::PriorityWeightings.new }

  let(:prioritisation_gateway) do
    PrioritisationGatewayDouble.new(
      tenancy_ref => {
        priority_band: priority_band,
        priority_score: priority_score,
        criteria: criteria,
        weightings: weightings
      }
    )
  end

  let(:sync_case) do
    described_class.new(
      prioritisation_gateway: prioritisation_gateway,
      stored_tenancies_gateway: stored_tenancies_gateway
    )
  end

  context 'when given a tenancy ref' do
    let(:tenancy_ref) { '000009/01' }
    let(:priority_band) { :green }
    let(:priority_score) { 1000 }

    it 'syncs the case\'s priority score' do
      expect(stored_tenancies_gateway).to receive(:store_tenancy).with(
        tenancy_ref: '000009/01',
        priority_band: :green,
        priority_score: 1000,
        criteria: criteria,
        weightings: weightings
      )

      subject
    end
  end

  context 'when given a different tenancy ref with different priorities' do
    let(:tenancy_ref) { '000010/01' }
    let(:priority_band) { :red }
    let(:priority_score) { 5000 }

    it 'syncs the tenancy\'s priority score' do
      expect(stored_tenancies_gateway).to receive(:store_tenancy).with(
        tenancy_ref: '000010/01',
        priority_band: :red,
        priority_score: 5000,
        criteria: criteria,
        weightings: weightings
      )

      subject
    end
  end
end

class PrioritisationGatewayDouble
  def initialize(tenancy_refs_to_priorities = {})
    @tenancy_refs_to_priorities = tenancy_refs_to_priorities
  end

  def priorities_for_tenancy(tenancy_ref)
    {
      priority_score: @tenancy_refs_to_priorities.dig(tenancy_ref, :priority_score),
      priority_band: @tenancy_refs_to_priorities.dig(tenancy_ref, :priority_band),
      criteria: @tenancy_refs_to_priorities.dig(tenancy_ref, :criteria),
      weightings: @tenancy_refs_to_priorities.dig(tenancy_ref, :weightings)
    }
  end
end
