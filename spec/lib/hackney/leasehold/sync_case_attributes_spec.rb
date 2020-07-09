require 'rails_helper'

describe Hackney::Leasehold::SyncCaseAttributes do
  subject { sync_case.execute(tenancy_ref: tenancy_ref) }

  let(:stub_tenancy_object) { double }
  let(:stored_tenancies_gateway) { double(store_tenancy: stub_tenancy_object) }
  let(:criteria) { Stubs::StubLeaseholdCriteria.new }

  let(:prioritisation_gateway) do
    PrioritisationGatewayDouble.new(
      tenancy_ref => {
        criteria: criteria
      }
    )
  end

  let(:sync_case) do
    described_class.new(
      prioritisation_gateway: prioritisation_gateway,
      stored_tenancies_gateway: stored_tenancies_gateway
    )
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
