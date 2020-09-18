require 'rails_helper'

describe Hackney::PDF::IncomePreview do
  subject do
    described_class.new(
      get_templates_gateway: get_templates_gateway,
      income_information_gateway: income_information_gateway,
      tenancy_case_gateway: tenancy_case_gateway
    )
  end

  let(:get_templates_gateway) { instance_double(Hackney::PDF::GetTemplatesForUser) }
  let(:income_information_gateway) { instance_double(Hackney::Income::UniversalHousingIncomeGateway) }
  let(:tenancy_case_gateway) { Hackney::Income::SqlTenancyCaseGateway.new }
  let(:username) { Faker::Name.name }
  let(:test_template_id) { 123_123 }
  let(:test_collectable_arrears) { 3506.90 }
  let(:test_template) do
    {
      path: 'spec/lib/hackney/pdf/test_income_template.erb',
      id: test_template_id
    }
  end
  let(:test_tenancy_ref) { 1_234_567_890 }
  let(:test_payment_ref) { 1_234_567_890 }
  let(:test_property_ref) { 1_234_567_890 }
  let(:test_letter_params) do
    {
      tenancy_ref: test_tenancy_ref,
      payment_ref: test_payment_ref,
      property_ref: test_property_ref,
      address_line1: '508 Saint Cloud Road',
      address_line2: 'Southwalk',
      address_line3: 'London',
      address_line4: 'London',
      address_name_number: '',
      address_post_code: 'SE1 0SW',
      address_preamble: '',
      title: '',
      forename: 'Bloggs',
      surname: 'Joe',
      eviction_date: nil,
      rent: weekly_rent
    }
  end
  let(:user) do
    Hackney::Domain::User.new.tap do |u|
      u.name = username
      u.groups = ['income-collection-group']
    end
  end

  let(:translated_html) { File.open('spec/lib/hackney/pdf/translated_test_income_template.html').read }
  let(:weekly_rent) { Faker::Commerce.price(range: 10..100.0) }

  before do
    create(:case_priority,
           tenancy_ref: test_tenancy_ref,
           collectable_arrears: test_collectable_arrears,
           weekly_rent: weekly_rent)
  end

  it 'generates letter preview' do
    expect(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
    expect(tenancy_case_gateway).to receive(:find).with(tenancy_ref: test_tenancy_ref).and_call_original
    expect(get_templates_gateway).to receive(:execute).and_return([test_template])

    preview = subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, user: user)

    expect(preview).to include(
      case: test_letter_params,
      template: test_template,
      preview: translated_html,
      errors: []
    )
  end

  context 'when there\'s missing data' do
    let(:test_letter_params) do
      {
        tenancy_ref: test_tenancy_ref,
        payment_ref: test_payment_ref,
        property_ref: test_property_ref,
        address_line1: '508 Saint Cloud Road',
        address_line2: '',
        address_line3: '',
        address_line4: '',
        address_name_number: '',
        address_post_code: '',
        address_preamble: '',
        title: '',
        forename: '',
        surname: '',
        total_collectable_arrears_balance: '3506.90'
      }
    end

    let(:translated_html) { File.open('spec/lib/hackney/pdf/translated_test_income_template_with_blanks.html').read }

    it 'generates letter preview with errors' do
      expect(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
      expect(get_templates_gateway).to receive(:execute).and_return([test_template])

      preview = subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, user: user)

      expect(preview).to include(
        case: test_letter_params,
        template: test_template,
        preview: translated_html,
        errors: [
          {
            name: 'forename',
            message: 'missing mandatory field'
          },
          {
            name: 'surname',
            message: 'missing mandatory field'
          },
          {
            name: 'address_line2',
            message: 'missing mandatory field'
          },
          {
            name: 'address_post_code',
            message: 'missing mandatory field'
          }
        ]
      )
    end
  end

  context 'when sending an informal agreement comfirmation letter' do
    let(:informal_agreement_comfirmation_template) do
      [
        {
          path: 'lib/hackney/pdf/templates/income/informal_agreement_confirmation_letter.erb',
          id: test_template_id
        }
      ]
    end
    let(:initial_payment_amount) { nil }
    let(:initial_payment_date) { nil }
    let(:frequency) { :weekly }
    let(:agreement) do
      build(:agreement, frequency: frequency, tenancy_ref: test_tenancy_ref, current_state: :live,
                        initial_payment_amount: initial_payment_amount,
                        initial_payment_date: initial_payment_date)
    end
    let(:rendered_letter) { subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, user: user, agreement: agreement) }

    before do
      allow(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
      allow(tenancy_case_gateway).to receive(:find).with(tenancy_ref: test_tenancy_ref).and_call_original
      allow(get_templates_gateway).to receive(:execute).and_return(informal_agreement_comfirmation_template)
    end

    context 'when its a regular payment agreement' do
      it 'fetches rent and formats the agreement params and renders the right content' do
        expect_any_instance_of(Hackney::PDF::IncomePreviewGenerator)
          .to receive(:execute).with(
            letter_params: test_letter_params.merge(
              agreement_frequency: agreement.frequency,
              amount: agreement.amount,
              date_of_first_payment: agreement.start_date,
              rent: BigDecimal(weekly_rent, 4),
              title: '',
              total_collectable_arrears_balance: BigDecimal(test_collectable_arrears, 5)
            ),
            username: username
          ).and_call_original

        expect(rendered_letter[:preview]).to include("#{agreement.frequency.humanize} rent: £#{weekly_rent}")
        expect(rendered_letter[:preview]).to include("Amount towards the arrears: £#{agreement.amount}")
        expect(rendered_letter[:preview]).to include("Total amount payable £#{format('%.2f', agreement.amount + weekly_rent)} #{agreement.frequency}")
        expect(rendered_letter[:preview]).to include("Date of first #{agreement.frequency} payment: #{agreement.start_date.strftime('%d %B %Y')}")
        expect(rendered_letter[:preview]).not_to include('Lump-sum payment amount:')
        expect(rendered_letter[:preview]).not_to include('Lump-sum payment date:')
      end
    end

    context 'when its a variable payment agreement' do
      let(:initial_payment_amount) { Faker::Commerce.price(range: 10...100) }
      let(:initial_payment_date) { Faker::Date.between(from: 10.days.ago, to: Date.today) }

      it 'fetches rent and formats the agreement params and renders the right content' do
        expect_any_instance_of(Hackney::PDF::IncomePreviewGenerator)
          .to receive(:execute).with(
            letter_params: test_letter_params.merge(
              agreement_frequency: agreement.frequency,
              amount: agreement.amount,
              date_of_first_payment: agreement.start_date,
              rent: BigDecimal(weekly_rent, 4),
              initial_payment_amount: initial_payment_amount,
              initial_payment_date: initial_payment_date,
              title: '',
              total_collectable_arrears_balance: BigDecimal(test_collectable_arrears, 5)
            ),
            username: username
          ).and_call_original

        expect(rendered_letter[:preview]).to include("Lump-sum payment amount: £#{agreement.initial_payment_amount}")
        expect(rendered_letter[:preview]).to include("Lump-sum payment date: #{agreement.initial_payment_date.strftime('%d %B %Y')}")
        expect(rendered_letter[:preview]).to include("#{agreement.frequency.humanize} rent: £#{weekly_rent}")
        expect(rendered_letter[:preview]).to include("Amount towards the arrears: £#{agreement.amount}")
        expect(rendered_letter[:preview]).to include("Total amount payable £#{format('%.2f', agreement.amount + weekly_rent)} #{agreement.frequency}")
        expect(rendered_letter[:preview]).to include("Date of first #{agreement.frequency} payment: #{agreement.start_date.strftime('%d %B %Y')}")
      end
    end

    context 'when its a one off payment agreement' do
      let(:frequency) { :one_off }

      it 'renders the right content' do
        expect(rendered_letter[:preview]).to include("Amount towards the rent: £#{weekly_rent}")
        expect(rendered_letter[:preview]).to include("Amount towards the arrears: £#{agreement.amount}")
        expect(rendered_letter[:preview]).to include("Total amount payable £#{format('%.2f', agreement.amount + weekly_rent)}")
        expect(rendered_letter[:preview]).to include("Date of payment: #{agreement.start_date.strftime('%d %B %Y')}")
      end
    end
  end

  context 'when sending an agreement breach letter' do
    let(:agreement) { create(:agreement, tenancy_ref: test_tenancy_ref, current_state: :breached) }
    let(:state) { create(:agreement_state, :breached, agreement: agreement, expected_balance: 500, checked_balance: 1000) }

    it 'formats the agreement params' do
      expect_any_instance_of(Hackney::PDF::IncomePreviewGenerator)
        .to receive(:execute).with(
          letter_params: test_letter_params.merge(
            created_date: agreement.created_at,
            expected_balance: state.expected_balance,
            checked_balance: state.checked_balance,
            total_collectable_arrears_balance: BigDecimal(test_collectable_arrears, 5),
            rent: BigDecimal(weekly_rent, 4)
          ),
          username: username
        ).and_call_original

      expect(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
      expect(tenancy_case_gateway).to receive(:find).with(tenancy_ref: test_tenancy_ref).and_call_original
      expect(get_templates_gateway).to receive(:execute).and_return([test_template])

      subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, user: user, agreement: agreement)
    end
  end

  context 'when sending a court outcome letter' do
    let(:court_case) { create(:court_case, tenancy_ref: test_tenancy_ref) }
    let(:agreement) { create(:agreement, tenancy_ref: test_tenancy_ref) }

    it 'fetches formats the court case params' do
      expect_any_instance_of(Hackney::PDF::IncomePreviewGenerator)
        .to receive(:execute).with(
          letter_params: test_letter_params.merge(
            rent: BigDecimal(weekly_rent, 4),
            court_date: court_case.court_date,
            court_outcome: court_case.court_outcome,
            title: '',
            total_collectable_arrears_balance: BigDecimal(test_collectable_arrears, 5)
          ),
          username: username
        ).and_call_original

      expect(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
      expect(tenancy_case_gateway).to receive(:find).with(tenancy_ref: test_tenancy_ref).and_call_original
      expect(get_templates_gateway).to receive(:execute).and_return([test_template])

      subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, user: user, court_case: court_case)
    end

    context 'when sending a court outcome letter with terms' do
      let(:court_case) { create(:court_case, tenancy_ref: test_tenancy_ref, court_outcome: Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_ON_TERMS, terms: true) }
      let(:court_outcome_letter_template) do
        [
          {
            path: 'lib/hackney/pdf/templates/income/court_outcome_letter.erb',
            id: test_template_id
          }
        ]
      end
      let(:initial_payment_amount) { nil }
      let(:initial_payment_date) { nil }
      let(:frequency) { :weekly }
      let(:agreement) do
        build(:agreement, frequency: frequency, tenancy_ref: test_tenancy_ref, current_state: :live,
                          initial_payment_amount: initial_payment_amount,
                          initial_payment_date: initial_payment_date)
      end
      let(:rendered_letter) { subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, user: user, court_case: court_case, agreement: agreement) }

      before do
        allow(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
        allow(get_templates_gateway).to receive(:execute).and_return(court_outcome_letter_template)
      end

      context 'when it has a regular payment agreement' do
        it 'fetches formats the court case params' do
          expect_any_instance_of(Hackney::PDF::IncomePreviewGenerator)
            .to receive(:execute).with(
              letter_params: test_letter_params.merge(
                rent: BigDecimal(weekly_rent, 4),
                court_date: court_case.court_date,
                court_outcome: court_case.court_outcome,
                agreement_frequency: agreement.frequency,
                amount: agreement.amount,
                balance_on_court_outcome_date: court_case.balance_on_court_outcome_date,
                date_of_first_payment: agreement.start_date,
                title: '',
                total_collectable_arrears_balance: BigDecimal(test_collectable_arrears, 5)
              ),
              username: username
            ).and_call_original

          expect(tenancy_case_gateway).to receive(:find).with(tenancy_ref: test_tenancy_ref).and_call_original

          expect(rendered_letter[:preview])
            .to include("The Court has decided that you must pay the Council the total amount of £#{court_case.balance_on_court_outcome_date} by instalments of")
          expect(rendered_letter[:preview]).to include("#{agreement.frequency.humanize} rent: £#{weekly_rent}")
          expect(rendered_letter[:preview]).to include("Amount towards the arrears: £#{agreement.amount}")
          expect(rendered_letter[:preview]).to include("Total amount payable £#{format('%.2f', agreement.amount + weekly_rent)} #{agreement.frequency}")
          expect(rendered_letter[:preview]).to include("Date of first #{agreement.frequency} payment: #{agreement.start_date.strftime('%d %B %Y')}")
          expect(rendered_letter[:preview]).not_to include('Lump-sum payment amount:')
          expect(rendered_letter[:preview]).not_to include('Lump-sum payment date:')
        end
      end

      context 'when it has a variable payment agreement' do
        let(:initial_payment_amount) { Faker::Commerce.price(range: 10...100) }
        let(:initial_payment_date) { Faker::Date.between(from: 10.days.ago, to: Date.today) }

        it 'fetches formats the court case params' do
          expect_any_instance_of(Hackney::PDF::IncomePreviewGenerator)
            .to receive(:execute).with(
              letter_params: test_letter_params.merge(
                rent: BigDecimal(weekly_rent, 4),
                court_date: court_case.court_date,
                court_outcome: court_case.court_outcome,
                agreement_frequency: agreement.frequency,
                amount: agreement.amount,
                balance_on_court_outcome_date: court_case.balance_on_court_outcome_date,
                date_of_first_payment: agreement.start_date,
                initial_payment_amount: initial_payment_amount,
                initial_payment_date: initial_payment_date,
                title: '',
                total_collectable_arrears_balance: BigDecimal(test_collectable_arrears, 5)
              ),
              username: username
            ).and_call_original

          expect(tenancy_case_gateway).to receive(:find).with(tenancy_ref: test_tenancy_ref).and_call_original

          expect(rendered_letter[:preview])
            .to include("The Court has decided that you must pay the Council the total amount of £#{court_case.balance_on_court_outcome_date} by instalments of")
          expect(rendered_letter[:preview]).to include("Lump-sum payment amount: £#{agreement.initial_payment_amount}")
          expect(rendered_letter[:preview]).to include("Lump-sum payment date: #{agreement.initial_payment_date.strftime('%d %B %Y')}")
          expect(rendered_letter[:preview]).to include("#{agreement.frequency.humanize} rent: £#{weekly_rent}")
          expect(rendered_letter[:preview]).to include("Amount towards the arrears: £#{agreement.amount}")
          expect(rendered_letter[:preview]).to include("Total amount payable £#{format('%.2f', agreement.amount + weekly_rent)} #{agreement.frequency}")
          expect(rendered_letter[:preview]).to include("Date of first #{agreement.frequency} payment: #{agreement.start_date.strftime('%d %B %Y')}")
        end
      end
    end
  end

  context 'when sending an court date letter' do
    let(:court_case) { create(:court_case, tenancy_ref: test_tenancy_ref, court_date: '01/01/2020') }

    it 'formats the court case params' do
      expect_any_instance_of(Hackney::PDF::IncomePreviewGenerator)
        .to receive(:execute).with(
          letter_params: test_letter_params.merge(
            court_date: court_case.court_date,
            court_outcome: court_case.court_outcome,
            total_collectable_arrears_balance: BigDecimal(test_collectable_arrears, 5),
            rent: BigDecimal(weekly_rent, 4)
          ),
          username: username
        ).and_call_original

      expect(income_information_gateway).to receive(:get_income_info).with(tenancy_ref: test_tenancy_ref).and_return(test_letter_params)
      expect(tenancy_case_gateway).to receive(:find).with(tenancy_ref: test_tenancy_ref).and_call_original
      expect(get_templates_gateway).to receive(:execute).and_return([test_template])

      subject.execute(tenancy_ref: test_tenancy_ref, template_id: test_template_id, user: user, court_case: court_case)
    end
  end
end
