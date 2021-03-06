require 'rails_helper'

describe Hackney::Income::WorktrayItemGateway do
  let(:gateway) { described_class.new }

  let(:tenancy_model) { Hackney::Income::Models::CasePriority }

  context 'when storing a tenancy' do
    subject(:store_worktray_item) { gateway.store_worktray_item(attributes) }

    let(:tenancy_ref) { Faker::Internet.slug }
    let(:attributes) do
      {
        tenancy_ref: tenancy_ref,
        criteria: stubbed_criteria,
        classification: classification
      }
    end

    let(:stubbed_criteria) { Stubs::StubCriteria.new }
    let(:classification) { 'no_action' }

    context 'when the tenancy does not already exist' do
      let(:created_tenancy) { tenancy_model.find_by(tenancy_ref: attributes.fetch(:tenancy_ref)) }

      it 'creates the tenancy' do
        store_worktray_item
        expect(created_tenancy).to have_attributes(expected_serialised_tenancy(attributes, nil))
      end

      # FIXME: shouldn't return AR models from gateways
      it 'returns the tenancy' do
        expect(store_worktray_item).to eq(created_tenancy)
      end
    end

    context 'when the tenancy already exists' do
      let(:court_case) { create(:court_case, tenancy_ref: tenancy_ref) }
      let!(:pre_existing_tenancy) do
        tenancy_model.create!(
          tenancy_ref: attributes.fetch(:tenancy_ref),
          balance: attributes.fetch(:criteria).balance,
          weekly_rent: attributes.fetch(:criteria).weekly_rent,
          days_since_last_payment: attributes.fetch(:criteria).days_since_last_payment,
          nosp_served: attributes.fetch(:criteria).nosp_served?,
          active_nosp: attributes.fetch(:criteria).active_nosp?,
          patch_code: attributes.fetch(:criteria).patch_code,
          courtdate: court_case.court_date,
          court_outcome: court_case.court_outcome,
          eviction_date: attributes.fetch(:criteria).eviction_date,
          universal_credit: attributes.fetch(:criteria).universal_credit,
          uc_rent_verification: attributes.fetch(:criteria).uc_rent_verification,
          uc_direct_payment_requested: attributes.fetch(:criteria).uc_direct_payment_requested,
          uc_direct_payment_received: attributes.fetch(:criteria).uc_direct_payment_received,
          classification: classification
        )
      end
      let(:stored_tenancy) { tenancy_model.find_by(tenancy_ref: attributes.fetch(:tenancy_ref)) }

      it 'updates the tenancy' do
        store_worktray_item
        expect(stored_tenancy).to have_attributes(expected_serialised_tenancy(attributes, court_case))
      end

      it 'does not create a new tenancy' do
        store_worktray_item
        expect(tenancy_model.count).to eq(1)
      end

      # FIXME: shouldn't return AR models from gateways
      it 'returns the tenancy' do
        expect(store_worktray_item).to eq(pre_existing_tenancy)
      end
    end
  end

  context 'when retrieving tenancies' do
    subject { gateway.get_tenancies }

    context 'when there are multiple tenancies' do
      let(:multiple_attributes) do
        multiple_attributes = []
        Faker::Number.number(digits: 1).to_i.times do
          multiple_attributes.append(
            tenancy_ref: Faker::Internet.slug,
            balance: Faker::Number.number(digits: 3).to_i
          )
        end
        multiple_attributes
      end

      context 'when the tenancies exist' do
        before do
          multiple_attributes.map do |attributes|
            tenancy_model.create!(
              tenancy_ref: attributes.fetch(:tenancy_ref),
              balance: attributes.fetch(:balance)
            )
          end
        end

        it 'includes the tenancy\'s ref, band and score' do
          expect(subject.count).to eq(multiple_attributes.count)

          multiple_attributes.each do |attributes|
            expect(subject).to include(a_hash_including(
                                         tenancy_ref: attributes.fetch(:tenancy_ref)
                                       ))
          end
        end

        context 'when cases are assigned different bands, scores and balances' do
          let(:multiple_attributes) do
            [
              { tenancy_ref: Faker::Internet.slug, balance: 1 },
              { tenancy_ref: Faker::Internet.slug, balance: 3 },
              { tenancy_ref: Faker::Internet.slug, balance: 2 },
              { tenancy_ref: Faker::Internet.slug, balance: 4 },
              { tenancy_ref: Faker::Internet.slug, balance: 11 },
              { tenancy_ref: Faker::Internet.slug, balance: 10 }
            ]
          end

          let(:cases) do
            subject.map do |c|
              { balance: c.fetch(:balance).to_i }
            end
          end

          it 'sorts by balance' do
            expect(cases).to eq([
              { balance: 11 },
              { balance: 10 },
              { balance: 4 },
              { balance: 3 },
              { balance: 2 },
              { balance: 1 }
            ])
          end

          context 'with page number set to one, and number per page set to two' do
            subject { gateway.get_tenancies(page_number: 1, number_per_page: 2) }

            it 'only return the first two' do
              expect(cases).to eq([
                { balance: 11 },
                { balance: 10 }
              ])
            end
          end

          context 'with page number set to two, and number per page set to three' do
            subject { gateway.get_tenancies(page_number: 2, number_per_page: 3) }

            it 'only return the last three' do
              expect(cases).to eq([
                { balance: 3 },
                { balance: 2 },
                { balance: 1 }
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
    let(:pause_reason_filter) { nil }

    let(:num_paused_cases_without_reason) { Faker::Number.between(from: 2, to: 10) }
    let(:num_paused_cases_with_reason) { Faker::Number.between(from: 2, to: 10) }
    let(:num_paused_cases) { num_paused_cases_with_reason + num_paused_cases_without_reason }
    let(:num_active_cases) { Faker::Number.between(from: 2, to: 20) }
    let(:num_pages) { Faker::Number.between(from: 1, to: 5) }
    let(:pause_reason) { Faker::Lorem.word }
    let(:pause_comment) { Faker::Lorem.paragraph }
    let(:is_paused_until_date) { Faker::Date.forward(days: 3) }

    before do
      num_paused_cases_with_reason.times do
        create(:case_priority, balance: 40, is_paused_until: is_paused_until_date, pause_reason: pause_reason, pause_comment: pause_comment)
      end

      num_paused_cases_without_reason.times do
        create(:case_priority, balance: 40, is_paused_until: is_paused_until_date)
      end

      (num_active_cases - 2).times do
        create(:case_priority, balance: 40)
      end

      create_list(:case_priority, 2, balance: 40, is_paused_until: Faker::Date.backward(days: 1))
    end

    context 'when we call get_tenancies' do
      subject do
        gateway.get_tenancies(
          page_number: 1,
          number_per_page: 50,
          filters: {
            is_paused: is_paused,
            pause_reason: pause_reason_filter
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

        context 'when the is_paused_until_date is yesterday' do
          let(:is_paused_until_date) { 1.day.ago.to_date }

          it 'does not find any paused cases' do
            expect(subject.count).to eq(0)
          end
        end

        context 'when the is_paused_until_date is today' do
          let(:is_paused_until_date) { Time.zone.now.to_date }

          it 'does not find any paused cases' do
            expect(subject.count).to eq(0)
          end
        end

        context 'when the is_paused_until_date is tomorrow' do
          let(:is_paused_until_date) { 1.day.from_now.to_date }

          it 'does find any paused cases' do
            expect(subject.count).to eq(num_paused_cases)
          end
        end

        context 'when pause_reason is set to a real pause reason' do
          let(:pause_reason_filter) { pause_reason }

          it 'onlies return cases with the specific reason' do
            expect(subject.count).to eq(num_paused_cases_with_reason)

            expect(subject).to all(include(pause_reason: pause_reason))
            expect(subject).to all(include(pause_comment: pause_comment))
            expect(subject).to all(include(is_paused_until: is_paused_until_date))
          end
        end

        context 'when pause_reason is set to not a real pause reason' do
          let(:pause_reason_filter) { 'not a real pause reason' }

          it 'nothing is returned' do
            expect(subject.count).to eq(0)
          end
        end
      end

      context 'with is_paused set false' do
        let(:is_paused) { false }

        it 'only return unpaused tenancies' do
          expect(subject.count).to eq(num_active_cases)
        end

        context 'when the is_paused_until_date is yesterday' do
          let(:is_paused_until_date) { 1.day.ago.to_date }

          it 'does not find any paused cases' do
            expect(subject.count).to eq(num_active_cases + num_paused_cases)
          end
        end

        context 'when the is_paused_until_date is today' do
          let(:is_paused_until_date) { Time.zone.now.to_date }

          it 'does not find any paused cases' do
            expect(subject.count).to eq(num_active_cases + num_paused_cases)
          end
        end

        context 'when the is_paused_until_date is tomorrow' do
          let(:is_paused_until_date) { 1.day.from_now.to_date }

          it 'does filter any paused cases' do
            expect(subject.count).to eq(num_active_cases)
          end
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
            create(:case_priority, balance: 40, is_paused_until: Faker::Date.forward(days: 1), classification: :no_action)
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

    let(:num_pages) { Faker::Number.between(from: 1, to: 5) }

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
    let(:patch_1) { Faker::Lorem.characters(number: 3) }
    let(:patch_2) { Faker::Lorem.characters(number: 3) }

    let(:num_cases_in_patch_1) { Faker::Number.between(from: 2, to: 10) }
    let(:num_cases_in_patch_2) { Faker::Number.between(from: 2, to: 20) }
    let(:num_cases_in_no_patches) { Faker::Number.between(from: 1, to: 3) }
    let(:num_pages) { Faker::Number.between(from: 1, to: 5) }

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

  def expected_serialised_tenancy(attributes, court_case)
    {
      tenancy_ref: attributes.fetch(:tenancy_ref),
      balance: attributes.fetch(:criteria).balance,
      days_since_last_payment: attributes.fetch(:criteria).days_since_last_payment,
      nosp_served: attributes.fetch(:criteria).nosp_served?,
      active_nosp: attributes.fetch(:criteria).active_nosp?,
      patch_code: attributes.fetch(:criteria).patch_code,
      courtdate: court_case&.court_date,
      court_outcome: court_case&.court_outcome,
      eviction_date: attributes.fetch(:criteria).eviction_date,
      universal_credit: attributes.fetch(:criteria).universal_credit,
      uc_rent_verification: attributes.fetch(:criteria).uc_rent_verification,
      uc_direct_payment_requested: attributes.fetch(:criteria).uc_direct_payment_requested,
      uc_direct_payment_received: attributes.fetch(:criteria).uc_direct_payment_received,
      classification: classification
    }
  end
end
