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

  let(:automate_sending_letters) { spy }

  let(:sync_case) do
    described_class.new(
      automate_sending_letters: automate_sending_letters,
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
      ).and_return(
        Hackney::Income::Models::CasePriority.new(
          tenancy_ref: '000009/01',
          priority_band: :green,
          priority_score: 1000
        )
      )

      subject
    end
  end

  context 'when given a case priority' do
    let(:tenancy_ref) { '000009/01' }
    let(:priority_band) { :green }
    let(:priority_score) { 1000 }

    let(:case_priority) {
      build(:case_priority,
            tenancy_ref: tenancy_ref,
            classification: :send_letter_one,
            patch_code: Faker::Number.number(4))
    }

    it 'calls the automate_sending_letters usecase' do
      expect(stored_tenancies_gateway).to receive(:store_tenancy).and_return(case_priority)

      expect(automate_sending_letters).to receive(:execute).with(case_priority: case_priority)
      subject
    end
  end

  context 'when given a paused case priority' do
    let(:tenancy_ref) { '000009/01' }
    let(:priority_band) { :green }
    let(:priority_score) { 1000 }

    let(:case_priority) {
      build(:case_priority,
            tenancy_ref: tenancy_ref,
            classification: :send_letter_one,
            patch_code: Faker::Number.number(4),
            is_paused_until: Date.today + 2.days)
    }

    it 'automate_sending_letters usecase is not called' do
      expect(stored_tenancies_gateway).to receive(:store_tenancy).and_return(case_priority)

      expect(automate_sending_letters).not_to receive(:execute).with(case_priority: case_priority)
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
        priority_band: priority_band,
        priority_score: 5000,
        criteria: criteria,
        weightings: weightings
      ).and_return(
        Hackney::Income::Models::CasePriority.new(
          tenancy_ref: tenancy_ref,
          priority_band: priority_band,
          priority_score: priority_score
        )
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
