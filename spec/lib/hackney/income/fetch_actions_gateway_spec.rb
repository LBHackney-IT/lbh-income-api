require 'rails_helper'

describe Hackney::Income::FetchActionsGateway do
  let(:gateway) { described_class.new }

  let(:action_model) { Hackney::IncomeCollection::Action }

  context 'when retrieving leasehold actions' do
    subject { gateway.get_actions(service_area_type: :leasehold) }

    context 'when there is an action' do
      let!(:leasehold_action) { create(:leasehold_action) }

      before do
        create(:leasehold_action, service_area_type: :rent)
      end

      it 'retrieves the action' do
        expect(subject.count).to eq(1)
      end

      it { expect(subject.first).to be_a action_model }
      it { expect(subject.first).to eq(leasehold_action) }
    end

    context 'with page number set to one and number per page set to two' do
      subject { gateway.get_actions(page_number: 1, number_per_page: 2, service_area_type: :leasehold) }

      before do
        create_list(:leasehold_action, 4)
      end

      it 'only returns the first two' do
        expect(subject.count).to eq(2)
      end
    end

    context 'when there are paused and not paused actions' do
      let(:is_paused) { nil }
      let(:pause_reason_filter) { nil }

      let(:num_paused_cases_without_reason) { Faker::Number.between(from: 2, to: 10) }
      let(:num_paused_cases_with_reason) { Faker::Number.between(from: 2, to: 10) }
      let(:num_paused_cases) { num_paused_cases_with_reason + num_paused_cases_without_reason }
      let(:num_active_cases) { Faker::Number.between(from: 2, to: 20) }
      let(:num_pages) { Faker::Number.between(from: 1, to: 5) }
      let(:pause_reason) { Faker::Lorem.word }
      let(:pause_comment) { Faker::Lorem.paragraph }
      let(:pause_until) { Faker::Date.forward(days: 3) }

      before do
        num_paused_cases_with_reason.times do
          create(:leasehold_action, balance: 40, pause_until: pause_until, pause_reason: pause_reason, pause_comment: pause_comment)
        end

        num_paused_cases_without_reason.times do
          create(:leasehold_action, balance: 40, pause_until: pause_until)
        end

        (num_active_cases - 2).times do
          create(:leasehold_action, balance: 40)
        end

        create_list(:leasehold_action, 2, balance: 40, pause_until: Faker::Date.backward(days: 1))
      end

      context 'when we call get_actions' do
        subject do
          gateway.get_actions(
            service_area_type: :leasehold,
            page_number: 1,
            number_per_page: 50,
            filters: {
              is_paused: is_paused,
              pause_reason: pause_reason_filter
            }
          )
        end

        let(:is_paused) { nil }

        it 'returns all actions' do
          expect(subject.count).to eq(num_paused_cases + num_active_cases)
        end

        context 'when and is_paused is set true' do
          let(:is_paused) { true }

          it 'only return only paused tenancies' do
            expect(subject.count).to eq(num_paused_cases)
          end

          context 'when the pause_until is yesterday' do
            let(:pause_until) { 1.day.ago.to_date }

            it 'does not find any paused cases' do
              expect(subject.count).to eq(0)
            end
          end

          context 'when the pause_until is today' do
            let(:pause_until) { Time.zone.now.to_date }

            it 'does not find any paused cases' do
              expect(subject.count).to eq(0)
            end
          end

          context 'when the pause_until is tomorrow' do
            let(:pause_until) { 1.day.from_now.to_date }

            it 'does find any paused cases' do
              expect(subject.count).to eq(num_paused_cases)
            end
          end

          context 'when pause_reason is set to a real pause reason' do
            let(:pause_reason_filter) { pause_reason }

            it 'onlies return cases with the specific reason' do
              expect(subject.count).to eq(num_paused_cases_with_reason)

              expect(subject).to all(have_attributes(pause_reason: pause_reason))
              expect(subject).to all(have_attributes(pause_comment: pause_comment))
              expect(subject).to all(have_attributes(pause_until: pause_until))
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

          context 'when the pause_until is yesterday' do
            let(:pause_until) { 1.day.ago.to_date }

            it 'does not find any paused cases' do
              expect(subject.count).to eq(num_active_cases + num_paused_cases)
            end
          end

          context 'when the pause_until is today' do
            let(:pause_until) { Time.zone.now.to_date }

            it 'does not find any paused cases' do
              expect(subject.count).to eq(num_active_cases + num_paused_cases)
            end
          end

          context 'when the pause_until is tomorrow' do
            let(:pause_until) { 1.day.from_now.to_date }

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
            service_area_type: :leasehold,
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
              create(:leasehold_action, balance: 40, pause_until: Faker::Date.forward(days: 1), classification: :no_action)
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

    context 'when there are tenancies with different immediate actions' do
      let(:no_action) { 'no_action' }
      let(:send_letter_one) { 'send_letter_one' }

      let(:cases_with_no_action) { 5 }
      let(:cases_with_warning_letter_action) { 5 }

      let(:num_pages) { Faker::Number.between(from: 1, to: 5) }

      before do
        cases_with_no_action.times do
          create(:leasehold_action, balance: 40, classification: no_action)
        end

        cases_with_warning_letter_action.times do
          create(:leasehold_action, balance: 40, classification: send_letter_one)
        end
      end

      context 'when we call get_actions' do
        subject do
          gateway.get_actions(
            page_number: 1,
            number_per_page: 50,
            service_area_type: :leasehold,
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
          create(:leasehold_action, balance: 40, patch_code: patch_1)
        end

        num_cases_in_patch_2.times do
          create(:leasehold_action, balance: 40, patch_code: patch_2)
        end

        num_cases_in_no_patches.times do
          create(:leasehold_action, balance: 40, patch_code: nil)
        end
      end

      context 'when we call get_actions' do
        subject do
          gateway.get_actions(
            page_number: 1,
            number_per_page: 50,
            service_area_type: :leasehold,
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
            service_area_type: :leasehold,
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
  end

  def expected_num_pages(items, number_per_page)
    (items.to_f / number_per_page).ceil
  end
end
