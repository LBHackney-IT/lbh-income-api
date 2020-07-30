RSpec.shared_examples 'CreateAgreement' do
  subject { described_class.new(add_action_diary: add_action_diary, cancel_agreement: cancel_agreement) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:frequency) { 'weekly' }
  let(:created_by) { Faker::Name.name }
  let(:notes) { Faker::ChuckNorris.fact }
  let(:court_case) { create(:court_case, tenancy_ref: tenancy_ref) }

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
      notes: notes
    }
  end

  let(:add_action_diary) { spy }
  let(:cancel_agreement) { spy }

  it 'calls the add_action_diary when a new agreement is created' do
    create(:case_priority, tenancy_ref: tenancy_ref, balance: 100)

    subject.execute(new_agreement_params: new_agreement_params)

    expect(add_action_diary).to have_received(:execute).with(
      tenancy_ref: tenancy_ref,
      comment: expected_action_diray_note,
      username: created_by,
      action_code: 'AGR'
    )
  end

  context 'when the case priority does not exist' do
    it 'returns nil' do
      expect(subject.execute(new_agreement_params: new_agreement_params)).to be_nil
    end
  end

  context 'when there are no previous agreements for the tenancy' do
    it 'creates and returns a new live agreement' do
      create(:case_priority, tenancy_ref: tenancy_ref, balance: 100)

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
      expect(created_agreement.starting_balance).to eq(100)
      expect(created_agreement.created_by).to eq(created_by)
      expect(created_agreement.notes).to eq(notes)
    end
  end

  context 'when there is an existing live informal agreement for the tenancy' do
    before do
      create(:case_priority, tenancy_ref: tenancy_ref, balance: 200)

      existing_agreement_params[:agreement_type] = 'informal'

      existing_agreement = create(:agreement, existing_agreement_params)
      create(:agreement_state, :live, agreement_id: existing_agreement.id)
    end

    it 'creates and returns a new live agreement and cancelles the previous agreement' do
      new_agreement = subject.execute(new_agreement_params: new_agreement_params)

      agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).includes(:agreement_states)

      expect(agreements.count).to eq(2)

      expect(agreements.last.tenancy_ref).to eq(new_agreement.tenancy_ref)
      expect(cancel_agreement).to have_received(:execute).with(agreement_id: agreements.first.id)
    end
  end
end
