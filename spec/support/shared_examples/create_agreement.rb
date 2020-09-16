RSpec.shared_examples 'CreateAgreement' do
  subject { described_class.new(add_action_diary: add_action_diary, cancel_agreement: cancel_agreement, update_agreement_state: update_agreement_state) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:frequency) { 'weekly' }
  let(:created_by) { Faker::Name.name }
  let(:notes) { Faker::ChuckNorris.fact }
  let(:court_case) { create(:court_case, tenancy_ref: tenancy_ref) }
  let(:initial_payment_amount) { nil }
  let(:initial_payment_date) { nil }
  let(:current_balance) { 100 }

  let(:existing_agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      frequency: frequency,
      created_by: created_by,
      notes: notes
    }
  end

  let(:new_agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      agreement_type: agreement_type,
      amount: amount,
      start_date: start_date,
      frequency: frequency,
      created_by: created_by,
      court_case_id: court_case.id,
      notes: notes,
      initial_payment_amount: initial_payment_amount,
      initial_payment_date: initial_payment_date
    }
  end

  let(:add_action_diary) { spy }
  let(:cancel_agreement) { spy }
  let(:update_agreement_state) { spy }

  before do
    create(:case_priority, tenancy_ref: tenancy_ref, balance: current_balance)
  end

  it 'calls the add_action_diary when a new agreement is created' do
    subject.execute(new_agreement_params: new_agreement_params)

    expect(add_action_diary).to have_received(:execute).with(
      tenancy_ref: tenancy_ref,
      comment: expected_action_diray_note,
      username: created_by,
      action_code: 'AGR'
    )
  end

  it 'calls update agreement state to make sure the state is always up to date' do
    agreement = subject.execute(new_agreement_params: new_agreement_params)

    expect(update_agreement_state).to have_received(:execute).with(
      agreement: agreement,
      current_balance: current_balance
    )
  end

  it 'creates a new live state with expected balance and description' do
    subject.execute(new_agreement_params: new_agreement_params)

    created_agreement = subject.execute(new_agreement_params: new_agreement_params)

    new_state = created_agreement.agreement_states.first
    expect(new_state.agreement_state).to eq('live')

    if created_agreement.formal?
      expect(new_state.expected_balance).to eq(court_case.balance_on_court_outcome_date)
      expect(new_state.checked_balance).to eq(court_case.balance_on_court_outcome_date)
    else
      expect(new_state.expected_balance).to eq(100)
      expect(new_state.checked_balance).to eq(100)
    end

    expect(new_state.description).to eq('Agreement created')
  end

  context 'when the case priority does not exist' do
    it 'returns nil' do
      new_agreement_params[:tenancy_ref] = 'NOTEXST'
      expect(subject.execute(new_agreement_params: new_agreement_params)).to be_nil
    end
  end

  context 'when there are no previous agreements for the tenancy' do
    it 'creates and returns a new live agreement' do
      created_agreement = subject.execute(new_agreement_params: new_agreement_params)

      latest_agreement_id = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).first.id
      expect(created_agreement).to be_an_instance_of(Hackney::Income::Models::Agreement)
      expect(created_agreement.id).to eq(latest_agreement_id)
      expect(created_agreement.tenancy_ref).to eq(tenancy_ref)
      expect(created_agreement.agreement_type).to eq(agreement_type)
      expect(created_agreement.amount).to eq(amount)
      expect(created_agreement.start_date).to eq(start_date)
      expect(created_agreement.frequency).to eq(frequency)
      expect(created_agreement.current_state).to eq('live')

      if created_agreement.formal?
        expect(created_agreement.starting_balance).to eq(court_case.balance_on_court_outcome_date)
      else
        expect(created_agreement.starting_balance).to eq(100)
      end

      expect(created_agreement.created_by).to eq(created_by)
      expect(created_agreement.notes).to eq(notes)
    end
  end

  context 'when there is an existing live informal agreement for the tenancy' do
    before do
      existing_agreement_params[:agreement_type] = 'informal'

      existing_agreement = create(:agreement, existing_agreement_params)
      create(:agreement_state, :live, agreement: existing_agreement)
    end

    it 'creates and returns a new live agreement and cancelles the previous agreement' do
      new_agreement = subject.execute(new_agreement_params: new_agreement_params)

      agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).includes(:agreement_states)

      expect(agreements.count).to eq(2)

      expect(agreements.last.tenancy_ref).to eq(new_agreement.tenancy_ref)
      expect(cancel_agreement).to have_received(:execute).with(agreement_id: agreements.first.id)
    end
  end

  context 'when its a variable payment agreement' do
    let(:initial_payment_amount) { Faker::Commerce.price(range: 10...200) }
    let(:initial_payment_date) { Faker::Date.between(from: 10.days.ago, to: 3.days.ago) }

    it 'creates and returns a new live agreement that has an initial payment amount and date' do
      new_agreement = subject.execute(new_agreement_params: new_agreement_params)

      expect(new_agreement.initial_payment_amount).to eq(initial_payment_amount)
      expect(new_agreement.initial_payment_date).to eq(initial_payment_date)
      expect(new_agreement).to be_variable_payment
    end
  end
end
