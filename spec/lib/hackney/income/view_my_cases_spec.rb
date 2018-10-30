require 'rails_helper'

describe Hackney::Income::ViewMyCases do
  let(:user_id) { Faker::Number.number(2).to_i }
  let(:page_number) { Faker::Number.number(2).to_i }
  let(:number_per_page) { Faker::Number.number(2).to_i }
  let(:tenancy_api_gateway) { TenancyApiGatewayDouble.new({}) }
  let(:stored_tenancies_gateway) { StoredTenancyGatewayDouble.new({}) }

  let(:view_my_cases) do
    described_class.new(
      tenancy_api_gateway: tenancy_api_gateway,
      stored_tenancies_gateway: stored_tenancies_gateway
    )
  end

  subject { view_my_cases.execute(user_id: user_id, page_number: page_number, number_per_page: number_per_page) }

  context 'when the stored tenancies gateway responds with no tenancies' do
    it 'should return nothing' do
      expect(subject.cases).to eq([])
    end
  end

  it 'should not do further queries if the page number returned is 0' do
    expect(stored_tenancies_gateway)
    .to receive(:number_of_pages_for_user)
        .with(a_hash_including(user_id: user_id))
        .and_call_original

    expect(stored_tenancies_gateway).not_to receive(:get_tenancies_for_user)

    expect(subject.cases).to eq([])
    expect(subject.number_of_pages).to eq(0)
  end

  context 'when the stored tenancies gateway responds with a tenancy' do
    let(:tenancy_attributes) { random_tenancy_attributes }
    let(:other_tenancy_attributes) { random_tenancy_attributes }
    let(:tenancy_priority_factors) { random_tenancy_priority_factors }
    let(:tenancy_priority_band) { Faker::Internet.slug }
    let(:tenancy_priority_score) { Faker::Number.number(5).to_i }
    let(:stored_tenancies_gateway) do
      StoredTenancyGatewayDouble.new(
        tenancy_attributes.fetch(:ref) => { tenancy_ref: tenancy_attributes.fetch(:ref), priority_band: tenancy_priority_band, priority_score: tenancy_priority_score }.merge(tenancy_priority_factors)
      )
    end

    it 'should pass the correct user id into the stored tenancy gateway' do
      expect(stored_tenancies_gateway)
      .to receive(:get_tenancies_for_user)
          .with(a_hash_including(user_id: user_id))
          .and_call_original

      subject
    end

    it 'should pass the correct page number and number per page into the stored tenancy gateway' do
      expect(stored_tenancies_gateway)
      .to receive(:get_tenancies_for_user)
          .with(a_hash_including(page_number: page_number, number_per_page: number_per_page))
          .and_call_original

      subject
    end

    context 'and full tenancy details can NOT be found' do
      it 'should ignore the tenancy' do
        expect(subject.cases).to eq([])
      end
    end

    context 'and full tenancy details can be found' do
      let(:tenancy_api_gateway) do
        TenancyApiGatewayDouble.new(
          other_tenancy_attributes.fetch(:ref) => other_tenancy_attributes,
          tenancy_attributes.fetch(:ref) => tenancy_attributes
        )
      end

      it 'should return full details for the correct tenancy' do
        expect(subject.cases.count).to eq(1)
        expect(subject.cases).to include(a_hash_including(
                                           ref: tenancy_attributes.fetch(:ref),
                                           priority_score: tenancy_priority_score,
                                           priority_band: tenancy_priority_band,
                                           current_balance: tenancy_attributes.fetch(:current_balance),
                                           current_arrears_agreement_status: tenancy_attributes.fetch(:current_arrears_agreement_status),

                                           latest_action: {
                                             code: tenancy_attributes.dig(:latest_action, :code),
                                             date: tenancy_attributes.dig(:latest_action, :date)
                                           },

                                           primary_contact: {
                                             name: tenancy_attributes.dig(:primary_contact, :name),
                                             short_address: tenancy_attributes.dig(:primary_contact, :short_address),
                                             postcode: tenancy_attributes.dig(:primary_contact, :postcode)
                                           },

                                           balance_contribution: tenancy_priority_factors.fetch(:balance_contribution),
                                           days_in_arrears_contribution: tenancy_priority_factors.fetch(:days_in_arrears_contribution),
                                           days_since_last_payment_contribution: tenancy_priority_factors.fetch(:days_since_last_payment_contribution),
                                           payment_amount_delta_contribution: tenancy_priority_factors.fetch(:payment_amount_delta_contribution),
                                           payment_date_delta_contribution: tenancy_priority_factors.fetch(:payment_date_delta_contribution),
                                           number_of_broken_agreements_contribution: tenancy_priority_factors.fetch(:number_of_broken_agreements_contribution),
                                           active_agreement_contribution: tenancy_priority_factors.fetch(:active_agreement_contribution),
                                           broken_court_order_contribution: tenancy_priority_factors.fetch(:broken_court_order_contribution),
                                           nosp_served_contribution: tenancy_priority_factors.fetch(:nosp_served_contribution),
                                           active_nosp_contribution: tenancy_priority_factors.fetch(:active_nosp_contribution),

                                           balance: tenancy_priority_factors.fetch(:balance),
                                           days_in_arrears: tenancy_priority_factors.fetch(:days_in_arrears),
                                           days_since_last_payment: tenancy_priority_factors.fetch(:days_since_last_payment),
                                           payment_amount_delta: tenancy_priority_factors.fetch(:payment_amount_delta),
                                           payment_date_delta: tenancy_priority_factors.fetch(:payment_date_delta),
                                           number_of_broken_agreements: tenancy_priority_factors.fetch(:number_of_broken_agreements),
                                           active_agreement: tenancy_priority_factors.fetch(:active_agreement),
                                           broken_court_order: tenancy_priority_factors.fetch(:broken_court_order),
                                           nosp_served: tenancy_priority_factors.fetch(:nosp_served),
                                           active_nosp: tenancy_priority_factors.fetch(:active_nosp)
                                         ))
      end

      context 'when filtering out paused cases' do
        subject { view_my_cases.execute(user_id: user_id, page_number: page_number, number_per_page: number_per_page, is_paused: false) }

        it 'should return only paused cases' do
          expect(stored_tenancies_gateway)
          .to receive(:get_tenancies_for_user)
              .with(a_hash_including(user_id: user_id, page_number: page_number, number_per_page: number_per_page, is_paused: false))
              .and_call_original

          expect(stored_tenancies_gateway)
          .to receive(:number_of_pages_for_user)
              .with(a_hash_including(user_id: user_id, number_per_page: number_per_page, is_paused: false))
              .and_call_original

          expect(subject.cases.count).to eq(1)
        end
      end
    end
  end

  context 'counting the number of pages of tenancies for a user' do
    let(:number_of_pages) { Faker::Number.number(3).to_i }

    it 'should consult the stored tenancies gateway' do
      expect(stored_tenancies_gateway).to receive(:number_of_pages_for_user).with(user_id: user_id, number_per_page: number_per_page, is_paused: nil).and_call_original
      subject
    end

    it 'should return what the stored tenancies gateway does' do
      allow(stored_tenancies_gateway).to receive(:number_of_pages_for_user).and_return(number_of_pages)
      expect(subject.number_of_pages).to eq(number_of_pages)
    end
  end

  it 'should be serialisable as valid JSON' do
    loaded_json = JSON.parse(subject.to_json)

    expect(loaded_json.fetch('cases')).to be_a(Array)
    expect(loaded_json.fetch('number_of_pages')).to be_an(Integer)
  end

  def random_tenancy_priority_factors
    {
      balance_contribution: Faker::Number.number(5),
      days_in_arrears_contribution: Faker::Number.number(5),
      days_since_last_payment_contribution: Faker::Number.number(5),
      payment_amount_delta_contribution: Faker::Number.number(5),
      payment_date_delta_contribution: Faker::Number.number(5),
      number_of_broken_agreements_contribution: Faker::Number.number(5),
      active_agreement_contribution: Faker::Number.number(5),
      broken_court_order_contribution: Faker::Number.number(5),
      nosp_served_contribution: Faker::Number.number(5),
      active_nosp_contribution: Faker::Number.number(5),

      balance: Faker::Commerce.price,
      days_in_arrears: Faker::Number.number(2),
      days_since_last_payment: Faker::Number.number(2),
      payment_amount_delta: Faker::Number.number(4),
      payment_date_delta: Faker::Number.number(1),
      number_of_broken_agreements: Faker::Number.number(1),
      active_agreement: Faker::Number.between(0, 1),
      broken_court_order: Faker::Number.between(0, 1),
      nosp_served: Faker::Number.between(0, 1),
      active_nosp: Faker::Number.between(0, 1)
    }
  end

  def random_tenancy_attributes(tenancy_ref = nil)
    {
      ref: tenancy_ref || Faker::Internet.slug,
      current_balance: Faker::Commerce.price,
      current_arrears_agreement_status: Faker::Internet.slug,
      latest_action: {
        code: Faker::Internet.slug,
        date: Faker::Time.forward(23, :morning)
      },
      primary_contact: {
        name: Faker::TheFreshPrinceOfBelAir.character,
        short_address: Faker::Address.street_address,
        postcode: Faker::Address.postcode
      }
    }
  end

  class TenancyApiGatewayDouble
    def initialize(tenancies_attributes)
      @tenancies_attributes = tenancies_attributes
    end

    def get_tenancies_by_refs(refs)
      refs.map { |ref| @tenancies_attributes[ref] }.compact
    end
  end

  class StoredTenancyGatewayDouble
    def initialize(stored_tenancies_attributes)
      @stored_tenancies_attributes = stored_tenancies_attributes
    end

    def get_tenancies_for_user(user_id:, page_number:, number_per_page:, is_paused: nil)
      @stored_tenancies_attributes.values
    end

    def number_of_pages_for_user(user_id:, number_per_page:, is_paused: nil)
      @stored_tenancies_attributes.keys.count
    end
  end
end
