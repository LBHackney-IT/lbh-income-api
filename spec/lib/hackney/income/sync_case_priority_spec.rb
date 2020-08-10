require 'rails_helper'

describe Hackney::Income::SyncCasePriority do
  subject { sync_case.execute(tenancy_ref: tenancy_ref) }

  let(:stub_tenancy_object) { double }
  let(:stored_worktray_item_gateway) { double(store_worktray_item: stub_tenancy_object) }
  let(:document_model) { Hackney::Cloud::Document }
  let(:agreement_model) { Hackney::Income::Models::Agreement }
  let(:criteria) { Stubs::StubCriteria.new }
  let(:tenancy_classification_stub) { double('Classifier') }

  let(:prioritisation_gateway) do
    PrioritisationGatewayDouble.new(
      tenancy_ref => {
        criteria: criteria
      }
    )
  end

  let(:automate_sending_letters) { spy }
  let(:update_agreement_state) { spy }

  let(:sync_case) do
    described_class.new(
      automate_sending_letters: automate_sending_letters,
      prioritisation_gateway: prioritisation_gateway,
      stored_worktray_item_gateway: stored_worktray_item_gateway,
      update_agreement_state: update_agreement_state
    )
  end

  before do
    expect(tenancy_classification_stub).to receive(:execute).once

    expect(document_model).to receive(:by_payment_ref).with(criteria.payment_ref).and_return([])

    expect(Hackney::Income::TenancyClassification::Classifier).to receive(:new)
      .with(instance_of(Hackney::Income::Models::CasePriority), criteria, [])
      .and_return(tenancy_classification_stub)
  end

  context 'when given a case priority' do
    let(:tenancy_ref) { '000009/01' }

    let(:case_priority) {
      build(:case_priority,
            tenancy_ref: tenancy_ref,
            classification: :send_letter_one,
            patch_code: Faker::Number.number(digits: 4))
    }

    it 'calls the automate_sending_letters usecase' do
      expect(stored_worktray_item_gateway).to receive(:store_worktray_item).and_return(case_priority)

      expect(automate_sending_letters).to receive(:execute).with(case_priority: case_priority)
      subject
    end
  end

  context 'when given a paused case priority' do
    let(:tenancy_ref) { '000009/01' }

    let(:case_priority) {
      build(:case_priority,
            tenancy_ref: tenancy_ref,
            classification: :send_letter_one,
            patch_code: Faker::Number.number(digits: 4),
            is_paused_until: Date.today + 2.days)
    }

    it 'automate_sending_letters usecase is not called' do
      expect(stored_worktray_item_gateway).to receive(:store_worktray_item).and_return(case_priority)

      expect(automate_sending_letters).not_to receive(:execute).with(case_priority: case_priority)
      subject
    end
  end

  context 'when there is an existing agreement' do
    let(:tenancy_ref) { '000009/01' }
    let(:agreement) { build(:agreement, tenancy_ref: tenancy_ref) }
    let(:case_priority) {
      build(:case_priority,
            tenancy_ref: tenancy_ref,
            classification: :send_letter_one,
            patch_code: Faker::Number.number(digits: 4),
            is_paused_until: Date.today + 2.days)
    }

    it 'updates the agreement state' do
      expect(stored_worktray_item_gateway).to receive(:store_worktray_item).and_return(case_priority)
      expect(agreement_model).to receive(:find_by).with(tenancy_ref: tenancy_ref).and_return(agreement)
      expect(update_agreement_state)
        .to receive(:execute)
        .with(agreement: agreement, current_balance: nil)
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
      criteria: @tenancy_refs_to_priorities.dig(tenancy_ref, :criteria)
    }
  end
end
