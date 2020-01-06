require 'rails_helper'

describe Hackney::Income::StoredTenanciesGateway do
  let(:gateway) { described_class.new }

  let(:tenancy_model) { Hackney::Income::Models::CasePriority }

  context 'when storing a tenancy' do
    subject(:store_tenancy) do
      gateway.store_tenancy(
        tenancy_ref: attributes.fetch(:tenancy_ref),
        priority_band: attributes.fetch(:priority_band),
        priority_score: attributes.fetch(:priority_score),
        criteria: attributes.fetch(:criteria),
        weightings: attributes.fetch(:weightings)
      )
    end

    let(:attributes) do
      {
        tenancy_ref: Faker::Internet.slug,
        priority_band: Faker::Internet.slug,
        priority_score: Faker::Number.number(5).to_i,
        criteria: stubbed_criteria,
        weightings: Hackney::Income::TenancyPrioritiser::PriorityWeightings.new
      }
    end

    let(:stubbed_criteria) { Stubs::StubCriteria.new }
    let(:tenancy_classification_stub) { double('TenancyClassification') }
    let(:classification) { 'no_action' }

    let(:score_calculator) do
      Hackney::Income::TenancyPrioritiser::Score.new(
        attributes.fetch(:criteria),
        attributes.fetch(:weightings)
      )
    end

    before do
      expect(tenancy_classification_stub).to receive(:execute).and_return(classification)
      expect(Hackney::Income::TenancyPrioritiser::TenancyClassification).to receive(:new)
        .with(instance_of(tenancy_model), stubbed_criteria)
        .and_return(tenancy_classification_stub)
    end

    context 'when the tenancy does not already exist' do
      let(:created_tenancy) { tenancy_model.find_by(tenancy_ref: attributes.fetch(:tenancy_ref)) }

      it 'creates the tenancy' do
        store_tenancy
        expect(created_tenancy).to have_attributes(expected_serialised_tenancy(attributes))
      end

      # FIXME: shouldn't return AR models from gateways
      it 'returns the tenancy' do
        expect(store_tenancy).to eq(created_tenancy)
      end
    end

    context 'when the tenancy already exists' do
      let!(:pre_existing_tenancy) do
        tenancy_model.create!(
          tenancy_ref: attributes.fetch(:tenancy_ref),
          priority_band: attributes.fetch(:priority_band),
          priority_score: attributes.fetch(:priority_score),

          balance_contribution: score_calculator.balance,
          days_in_arrears_contribution: score_calculator.days_in_arrears,
          days_since_last_payment_contribution: score_calculator.days_since_last_payment,
          payment_amount_delta_contribution: score_calculator.payment_amount_delta,
          payment_date_delta_contribution: score_calculator.payment_date_delta,
          number_of_broken_agreements_contribution: score_calculator.number_of_broken_agreements,
          active_agreement_contribution: score_calculator.active_agreement,
          broken_court_order_contribution: score_calculator.broken_court_order,
          nosp_served_contribution: score_calculator.nosp_served,
          active_nosp_contribution: score_calculator.active_nosp,

          balance: attributes.fetch(:criteria).balance,
          weekly_rent: attributes.fetch(:criteria).weekly_rent,
          days_in_arrears: attributes.fetch(:criteria).days_in_arrears,
          days_since_last_payment: attributes.fetch(:criteria).days_since_last_payment,
          payment_amount_delta: attributes.fetch(:criteria).payment_amount_delta,
          payment_date_delta: attributes.fetch(:criteria).payment_date_delta,
          number_of_broken_agreements: attributes.fetch(:criteria).number_of_broken_agreements,
          active_agreement: attributes.fetch(:criteria).active_agreement?,
          broken_court_order: attributes.fetch(:criteria).broken_court_order?,
          nosp_served: attributes.fetch(:criteria).nosp_served?,
          active_nosp: attributes.fetch(:criteria).active_nosp?,
          patch_code: attributes.fetch(:criteria).patch_code,
          courtdate: attributes.fetch(:criteria).courtdate,
          court_outcome: attributes.fetch(:criteria).court_outcome,
          eviction_date: attributes.fetch(:criteria).eviction_date,
          universal_credit: attributes.fetch(:criteria).universal_credit,
          uc_rent_verification: attributes.fetch(:criteria).uc_rent_verification,
          uc_direct_payment_requested: attributes.fetch(:criteria).uc_direct_payment_requested,
          uc_direct_payment_received: attributes.fetch(:criteria).uc_direct_payment_received,
          classification: classification,
          latest_active_agreement_date: attributes.fetch(:criteria).latest_active_agreement_date,
          breach_agreement_date: attributes.fetch(:criteria).latest_active_agreement_date,
          expected_balance: attributes.fetch(:criteria).expected_balance
        )
      end

      let(:stored_tenancy) { tenancy_model.find_by(tenancy_ref: attributes.fetch(:tenancy_ref)) }

      it 'updates the tenancy' do
        store_tenancy
        expect(stored_tenancy).to have_attributes(expected_serialised_tenancy(attributes))
      end

      it 'does not create a new tenancy' do
        store_tenancy
        expect(tenancy_model.count).to eq(1)
      end

      # FIXME: shouldn't return AR models from gateways
      it 'returns the tenancy' do
        expect(store_tenancy).to eq(pre_existing_tenancy)
      end
    end
  end

  context 'when retrieving tenancies' do
    subject { gateway.get_tenancies }

    context 'when there are multiple tenancies' do
      let(:multiple_attributes) do
        multiple_attributes = []
        Faker::Number.number(1).to_i.times do
          multiple_attributes.append(
            tenancy_ref: Faker::Internet.slug,
            priority_band: Faker::Internet.slug,
            priority_score: Faker::Number.number(5).to_i,
            balance: Faker::Number.number(3).to_i
          )
        end
        multiple_attributes
      end

      context 'when the tenancies exist' do
        before do
          multiple_attributes.map do |attributes|
            tenancy_model.create!(
              tenancy_ref: attributes.fetch(:tenancy_ref),
              priority_band: attributes.fetch(:priority_band),
              priority_score: attributes.fetch(:priority_score),
              balance: attributes.fetch(:balance)
            )
          end
        end

        it 'includes the tenancy\'s ref, band and score' do
          expect(subject.count).to eq(multiple_attributes.count)

          multiple_attributes.each do |attributes|
            expect(subject).to include(a_hash_including(
                                         tenancy_ref: attributes.fetch(:tenancy_ref),
                                         priority_band: attributes.fetch(:priority_band),
                                         priority_score: attributes.fetch(:priority_score)
                                       ))
          end
        end

        context 'when cases are assigned different bands, scores and balances' do
          let(:multiple_attributes) do
            [
              { tenancy_ref: Faker::Internet.slug, priority_band: 'red', priority_score: 1, balance: 1 },
              { tenancy_ref: Faker::Internet.slug, priority_band: 'green', priority_score: 50, balance: 3 },
              { tenancy_ref: Faker::Internet.slug, priority_band: 'green', priority_score: 100, balance: 2 },
              { tenancy_ref: Faker::Internet.slug, priority_band: 'amber', priority_score: 100, balance: 4 },
              { tenancy_ref: Faker::Internet.slug, priority_band: 'amber', priority_score: 10, balance: 11 },
              { tenancy_ref: Faker::Internet.slug, priority_band: 'red', priority_score: 101, balance: 10 }
            ]
          end

          let(:cases) do
            subject.map do |c|
              { balance: c.fetch(:balance).to_i, priority_band: c.fetch(:priority_band), priority_score: c.fetch(:priority_score).to_i }
            end
          end

          it 'sorts by balance' do
            expect(cases).to eq([
              { priority_band: 'amber', priority_score: 10, balance: 11 },
              { priority_band: 'red', priority_score: 101, balance: 10 },
              { priority_band: 'amber', priority_score: 100, balance: 4 },
              { priority_band: 'green', priority_score: 50, balance: 3 },
              { priority_band: 'green', priority_score: 100, balance: 2 },
              { priority_band: 'red', priority_score: 1, balance: 1 }
            ])
          end

          context 'with page number set to one, and number per page set to two' do
            subject { gateway.get_tenancies(page_number: 1, number_per_page: 2) }

            it 'only return the first two' do
              expect(cases).to eq([
                { priority_band: 'amber', priority_score: 10, balance: 11 },
                { priority_band: 'red', priority_score: 101, balance: 10 }
              ])
            end
          end

          context 'with page number set to two, and number per page set to three' do
            subject { gateway.get_tenancies(page_number: 2, number_per_page: 3) }

            it 'only return the last three' do
              expect(cases).to eq([
                { priority_band: 'green', priority_score: 50, balance: 3 },
                { priority_band: 'green', priority_score: 100, balance: 2 },
                { priority_band: 'red', priority_score: 1, balance: 1 }
              ])
            end
          end
        end
      end
    end
  end

  context 'when counting the number of pages of tenancies' do
    subject { gateway.number_of_pages(number_per_page: number_per_page) }

    context 'with there are ten tenancies in arrears and ten not in arrears' do
      before do
        create_list(:case_priority, 10, balance: 1)
        create_list(:case_priority, 10, balance: -1)
      end

      context 'when the number shown per page is five' do
        let(:number_per_page) { 5 }

        it { is_expected.to eq(2) }
      end
    end

    context 'when there are nine tenancies' do
      before { create_list(:case_priority, 9) }

      context 'with five results per page' do
        let(:number_per_page) { 5 }

        it { is_expected.to eq(2) }
      end
    end

    context 'when there are twelve tenancies' do
      before { create_list(:case_priority, 12) }

      context 'with three results per page' do
        let(:number_per_page) { 3 }

        it { is_expected.to eq(4) }
      end
    end
  end

  context 'when there are paused and not paused tenancies' do
    let(:is_paused) { nil }

    let(:num_paused_cases) { Faker::Number.between(2, 10) }
    let(:num_active_cases) { Faker::Number.between(2, 20) }
    let(:num_pages) { Faker::Number.between(1, 5) }

    before do
      num_paused_cases.times do
        create(:case_priority, balance: 40, is_paused_until: Faker::Date.forward(1))
      end

      (num_active_cases - 2).times do
        create(:case_priority, balance: 40)
      end

      create_list(:case_priority, 2, balance: 40, is_paused_until: Faker::Date.backward(1))
    end

    context 'when we call get_tenancies' do
      subject do
        gateway.get_tenancies(
          page_number: 1,
          number_per_page: 50,
          filters: {
            is_paused: is_paused
          }
        )
      end

      let(:is_paused) { nil }

      it 'returns all tenancies' do
        expect(subject.count).to eq(num_paused_cases + num_active_cases)
      end

      context 'when and is_paused is set true' do
        let(:is_paused) { true }

        it 'only return only paused tenancies' do
          expect(subject.count).to eq(num_paused_cases)
        end
      end

      context 'with is_paused set false' do
        let(:is_paused) { false }

        it 'only return unpaused tenancies' do
          expect(subject.count).to eq(num_active_cases)
        end
      end
    end

    context 'when we call number_of_pages' do
      subject do
        gateway.number_of_pages(
          number_per_page: num_pages,
          filters: {
            is_paused: is_paused
          }
        )
      end

      context 'with is_paused set false' do
        let(:is_paused) { false }

        it 'shows the number of pages of paused cases' do
          expect(subject).to eq(expected_num_pages(num_active_cases, num_pages))
        end
      end

      context 'with is_paused set true' do
        let(:is_paused) { true }

        it 'shows the number of pages of paused cases' do
          expect(subject).to eq(expected_num_pages(num_paused_cases, num_pages))
        end

        context 'with one no_action classification case' do
          before do
            create(:case_priority, balance: 40, is_paused_until: Faker::Date.forward(1), classification: :no_action)
          end

          it 'shows the number of pages of paused cases with one no_action classification' do
            expect(subject).to eq(expected_num_pages(num_paused_cases + 1, num_pages))
          end
        end
      end

      context 'with is_paused not set' do
        let(:is_paused) { nil }

        it 'shows the number of pages of paused cases' do
          expect(subject).to eq(expected_num_pages((num_paused_cases + num_active_cases), num_pages))
        end
      end
    end
  end

  context 'when there are tenancies upcoming eviction dates' do
    subject do
      gateway.get_tenancies(
        page_number: 1,
        number_per_page: 50,
        filters: {
          upcoming_evictions: true
        }
      )
    end

    let(:cases_with_upcoming_evictions) { 5 }
    let(:cases_with_no_upcoming_evictions) { 5 }

    before do
      cases_with_upcoming_evictions.times do |index|
        create(:case_priority, balance: 40 + index, eviction_date: Date.tomorrow + index)
      end
      cases_with_no_upcoming_evictions.times do |index|
        create(:case_priority, balance: 40 + index)
      end
    end

    it 'can return cases with upcoming eviction dates' do
      expect(subject.count).to eq(cases_with_upcoming_evictions)
    end

    it 'can return cases in order of their eviction date' do
      last_eviction_date_created = Date.tomorrow + cases_with_upcoming_evictions - 1
      create(:case_priority, balance: 40, eviction_date: Date.today)
      expect(subject.first[:eviction_date]).to eq(Date.today)
      expect(subject.last[:eviction_date]).to eq(last_eviction_date_created)
    end

    it 'can return cases in the future' do
      create(:case_priority, balance: 40, eviction_date: Date.yesterday)
      expect(subject.map { |v| v[:eviction_date] }.min).to be >= Time.zone.today
    end
  end

  context 'when there are tenancies with an upcoming courtdate' do
    let(:cases_with_courtdate_in_future) { 5 }
    let(:cases_with_courtdate_in_past) { 5 }

    before do
      cases_with_courtdate_in_future.times do
        create(:case_priority, balance: 40, classification: nil, courtdate: Date.today + 20)
      end

      cases_with_courtdate_in_past.times do
        create(:case_priority, balance: 40, classification: nil, courtdate: Date.today - 20)
      end
    end

    context 'when we call get_tenancies' do
      subject do
        gateway.get_tenancies(
          page_number: 1,
          number_per_page: 50,
          filters: {
            upcoming_court_dates: true
          }
        )
      end

      it 'returns only tenancies with an upcoming courtdate' do
        expect(subject.count).to eq(cases_with_courtdate_in_future)
      end
    end
  end

  context 'when there are tenancies with different immediate actions' do
    let(:no_action) { 'no_action' }
    let(:send_letter_one) { 'send_letter_one' }

    let(:cases_with_no_action) { 5 }
    let(:cases_with_warning_letter_action) { 5 }

    let(:num_pages) { Faker::Number.between(1, 5) }

    before do
      cases_with_no_action.times do
        create(:case_priority, balance: 40, classification: no_action)
      end

      cases_with_warning_letter_action.times do
        create(:case_priority, balance: 40, classification: send_letter_one)
      end
    end

    context 'when we call get_tenancies' do
      subject do
        gateway.get_tenancies(
          page_number: 1,
          number_per_page: 50,
          filters: {
            classification: classification,
            full_patch: full_patch
          }
        )
      end

      let(:full_patch) { false }

      context 'with no filter by classification' do
        let(:classification) { nil }

        it 'only returns tenancies with warning letters as next action' do
          expect(subject.count).to eq(cases_with_warning_letter_action)
        end

        context 'when the full_patch filter is set' do
          let(:full_patch) { true }

          it 'contains all cases' do
            expect(subject.count).to eq(cases_with_no_action + cases_with_warning_letter_action)
          end
        end
      end

      context 'when filtering by no_action' do
        let(:classification) { no_action }

        it 'only returns tennancies with then next immediate action of no_action' do
          expect(subject.count).to eq(cases_with_no_action)
        end
      end

      context 'when filtering by send_letter_one' do
        let(:classification) { send_letter_one }

        it 'only returns tennancies with then next immediate action of send_letter_one' do
          expect(subject.count).to eq(cases_with_warning_letter_action)
        end
      end
    end
  end

  context 'when there are tenancies with different patches' do
    let(:patch_1) { Faker::Lorem.characters(3) }
    let(:patch_2) { Faker::Lorem.characters(3) }

    let(:num_cases_in_patch_1) { Faker::Number.between(2, 10) }
    let(:num_cases_in_patch_2) { Faker::Number.between(2, 20) }
    let(:num_cases_in_no_patches) { Faker::Number.between(1, 3) }
    let(:num_pages) { Faker::Number.between(1, 5) }

    before do
      num_cases_in_patch_1.times do
        create(:case_priority, balance: 40, patch_code: patch_1)
      end

      num_cases_in_patch_2.times do
        create(:case_priority, balance: 40, patch_code: patch_2)
      end

      num_cases_in_no_patches.times do
        create(:case_priority, balance: 40, patch_code: nil)
      end
    end

    context 'when we call get_tenancies' do
      subject do
        gateway.get_tenancies(
          page_number: 1,
          number_per_page: 50,
          filters: {
            patch: patch
          }
        )
      end

      context 'with no filtering by patch' do
        let(:patch) { nil }

        it 'returns all tenancies' do
          expect(subject.count).to eq(num_cases_in_patch_1 + num_cases_in_patch_2 + num_cases_in_no_patches)
        end
      end

      context 'when filtering by assigned patches' do
        let(:patch) { 'unassigned' }

        it 'returns tenancies with no patches assigned' do
          expect(subject.count).to eq(num_cases_in_no_patches)
        end
      end

      context 'when filtering by patch 1' do
        let(:patch) { patch_1 }

        it 'only return only paused tenancies' do
          expect(subject.count).to eq(num_cases_in_patch_1)
        end
      end

      context 'when filtering by patch 2' do
        let(:patch) { patch_2 }

        it 'only return unpaused tenancies' do
          expect(subject.count).to eq(num_cases_in_patch_2)
        end
      end
    end

    context 'when calling #number_of_pages' do
      subject do
        gateway.number_of_pages(
          number_per_page: num_pages,
          filters: {
            patch: patch
          }
        )
      end

      context 'when filtering by patch 1' do
        let(:patch) { patch_1 }

        it 'returns the number of pages of paused cases' do
          expect(subject).to eq(expected_num_pages(num_cases_in_patch_1, num_pages))
        end
      end

      context 'when filtering by patch 2' do
        let(:patch) { patch_2 }

        it 'returns the number of pages of paused cases' do
          expect(subject).to eq(expected_num_pages(num_cases_in_patch_2, num_pages))
        end
      end

      context 'when no filtering by patch' do
        let(:patch) { nil }

        it 'returns the number of pages of paused cases' do
          expect(subject).to eq(expected_num_pages((num_cases_in_patch_1 + num_cases_in_patch_2 + num_cases_in_no_patches), num_pages))
        end
      end

      context 'when filtering by unassigned patches' do
        let(:patch) { 'unassigned' }

        it 'returns the number of pages of paused cases' do
          expect(subject).to eq(expected_num_pages(num_cases_in_no_patches, num_pages))
        end
      end
    end
  end

  def expected_num_pages(items, number_per_page)
    (items.to_f / number_per_page).ceil
  end

  def expected_serialised_tenancy(attributes)
    {
      tenancy_ref: attributes.fetch(:tenancy_ref),
      priority_band: attributes.fetch(:priority_band),
      priority_score: attributes.fetch(:priority_score),

      balance_contribution: score_calculator.balance,
      days_in_arrears_contribution: score_calculator.days_in_arrears,
      days_since_last_payment_contribution: score_calculator.days_since_last_payment,
      payment_amount_delta_contribution: score_calculator.payment_amount_delta,
      payment_date_delta_contribution: score_calculator.payment_date_delta,
      number_of_broken_agreements_contribution: score_calculator.number_of_broken_agreements,
      active_agreement_contribution: score_calculator.active_agreement,
      broken_court_order_contribution: score_calculator.broken_court_order,
      nosp_served_contribution: score_calculator.nosp_served,
      active_nosp_contribution: score_calculator.active_nosp,

      balance: attributes.fetch(:criteria).balance,
      days_in_arrears: attributes.fetch(:criteria).days_in_arrears,
      days_since_last_payment: attributes.fetch(:criteria).days_since_last_payment,
      payment_amount_delta: attributes.fetch(:criteria).payment_amount_delta,
      payment_date_delta: attributes.fetch(:criteria).payment_date_delta,
      number_of_broken_agreements: attributes.fetch(:criteria).number_of_broken_agreements,
      active_agreement: attributes.fetch(:criteria).active_agreement?,
      broken_court_order: attributes.fetch(:criteria).broken_court_order?,
      nosp_served: attributes.fetch(:criteria).nosp_served?,
      active_nosp: attributes.fetch(:criteria).active_nosp?,
      patch_code: attributes.fetch(:criteria).patch_code,
      courtdate: attributes.fetch(:criteria).courtdate,
      court_outcome: attributes.fetch(:criteria).court_outcome,
      eviction_date: attributes.fetch(:criteria).eviction_date,
      universal_credit: attributes.fetch(:criteria).universal_credit,
      uc_rent_verification: attributes.fetch(:criteria).uc_rent_verification,
      uc_direct_payment_requested: attributes.fetch(:criteria).uc_direct_payment_requested,
      uc_direct_payment_received: attributes.fetch(:criteria).uc_direct_payment_received,
      classification: classification,
      latest_active_agreement_date: attributes.fetch(:criteria).latest_active_agreement_date,
      breach_agreement_date: attributes.fetch(:criteria).breach_agreement_date,
      expected_balance: attributes.fetch(:criteria).expected_balance
    }
  end
end
