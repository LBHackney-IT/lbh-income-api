require 'rails_helper'
require 'notifications/client'
require 'schedules/tenancy_sync'

describe 'manually sending a letter causes case priority to sync', type: :request do
  include MockAwsHelper
  include ActiveJob::TestHelper

  let(:property_ref) { Faker::Number.number(4) }
  let(:tenancy_ref) { "#{Faker::Number.number(6)}/#{Faker::Number.number(2)}" }
  let(:payment_ref) { Faker::Number.number(4) }
  let(:house_ref) { Faker::Number.number(4) }
  let(:postcode) { Faker::Address.postcode }
  let(:leasedate) { Time.zone.now.beginning_of_hour }
  let(:template_id) { 'income_collection_letter_1' }
  let(:user_group) { 'income-collection-group' }
  let(:current_balance) { BigDecimal('525.00') }
  let(:gov_notify_client) { double(Notifications::Client) }
  let(:user) {
    {
      name: Faker::Name.name,
      email: Faker::Internet.email,
      groups: %w[leasehold-group income-group]
    }
  }
  let(:fake_response) {
    OpenStruct.new(
      id: Faker::Number.number,
      reference: SecureRandom.uuid,
      postage: 'second'
    )
  }

  let!(:original_env_can_auto_letters) { ENV['CAN_AUTOMATE_LETTERS'] }
  let!(:original_env_patch_codes_letters) { ENV['PATCH_CODES_FOR_LETTER_AUTOMATION'] }
  let!(:original_env_can_auto_letter_one) { ENV['AUTOMATE_INCOME_COLLECTION_LETTER_ONE'] }

  before do
    mock_aws_client
    create_valid_uh_records_for_an_income_letter(
      property_ref: property_ref,
      house_ref: house_ref,
      postcode: postcode,
      leasedate: leasedate
    )

    stub_const('Notifications::Client', gov_notify_client)
    allow(gov_notify_client).to receive(:new).and_return(gov_notify_client)
    allow(gov_notify_client).to receive(:send_precompiled_letter).and_return(fake_response)

    ENV['CAN_AUTOMATE_LETTERS'] = 'true'
    ENV['PATCH_CODES_FOR_LETTER_AUTOMATION'] = 'W02'
    ENV['AUTOMATE_INCOME_COLLECTION_LETTER_ONE'] = 'true'
  end

  after do
    ENV['CAN_AUTOMATE_LETTERS'] = original_env_can_auto_letters
    ENV['PATCH_CODES_FOR_LETTER_AUTOMATION'] = original_env_patch_codes_letters
    ENV['AUTOMATE_INCOME_COLLECTION_LETTER_ONE'] = original_env_can_auto_letter_one
  end

  describe 'POST /api/v1/messages/letters/send' do
    let(:income_use_case_factory) { Hackney::Income::UseCaseFactory.new }
    let(:case_priority) { Hackney::Income::Models::CasePriority.last }

    context 'with existing income collection letter' do
      let(:generate_and_store_income_collection_letter) {
        generate_and_store_letter(tenancy_ref: tenancy_ref, template_id: template_id, user: user)
      }

      before do
        generate_and_store_income_collection_letter
        income_use_case_factory.sync_case_priority.execute(tenancy_ref: tenancy_ref)

        stub_action_diary_write(tenancy_ref: tenancy_ref, code: 'IC1', date: Time.zone.now)
      end

      it 'pause case priority for resync when a user sends a letter' do
        expect(case_priority).to be_send_letter_one

        perform_enqueued_jobs(only: Hackney::Income::Jobs::SendLetterToGovNotifyJob) do
          post messages_letters_send_path, params: { uuid: generate_and_store_income_collection_letter[:uuid] }
        end

        document = Hackney::Cloud::Document.find_by(uuid: generate_and_store_income_collection_letter[:uuid])

        expect(document).to be_queued

        case_priority.reload
        expect(case_priority.paused?).to eq(true)
        expect(case_priority.is_paused_until).to eq(Date.tomorrow)
      end
    end
  end

  def generate_and_store_letter(tenancy_ref:, template_id:, user:)
    user_obj = Hackney::Domain::User.new.tap do |u|
      u.name = user[:name]
      u.email = user[:email]
      u.groups = user[:groups]
    end

    UseCases::GenerateAndStoreLetter.new.execute(
      tenancy_ref: tenancy_ref,
      payment_ref: nil,
      template_id: template_id,
      user: user_obj
    )
  end
end
