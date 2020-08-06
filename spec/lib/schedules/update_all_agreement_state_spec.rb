require 'rails_helper'
require 'schedules/update_all_agreement_state.rb'

describe 'Scheduling' do
  subject { UpdateAllAgreementState.new.perform }

  it 'enqueues UpdateAllAgreementState worker' do
    live_agreement_to_check = create_live_agreement(current_balance: 20, starting_balance: 100)
    live_agreement_to_breach = create_live_agreement(current_balance: 100, starting_balance: 100)
    live_agreement_to_complete = create_live_agreement(current_balance: 0, starting_balance: 100)
    create(:agreement_state, :cancelled)

    expect_any_instance_of(Hackney::Income::UpdateAgreementState).to receive(:execute).exactly(3).times.and_call_original

    subject

    [live_agreement_to_check, live_agreement_to_breach, live_agreement_to_complete].each(&:reload)

    expect(live_agreement_to_check.current_state).to eq('live')
    expect(live_agreement_to_breach.current_state).to eq('breached')
    expect(live_agreement_to_complete.current_state).to eq('completed')
  end

  def create_live_agreement(current_balance:, starting_balance:)
    tenancy_ref = Faker::Lorem.characters(number: 8)
    create(:case_priority, tenancy_ref: tenancy_ref, balance: current_balance)
    agreement = create(:agreement,
                       tenancy_ref: tenancy_ref,
                       start_date: Date.today - 10.days,
                       starting_balance: starting_balance,
                       frequency: :weekly,
                       amount: 30)
    create(:agreement_state, :live, agreement: agreement)
    agreement
  end
end
