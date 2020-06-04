require 'rails_helper'
require 'notifications/client'
require 'schedules/tenancy_sync'

describe 'syncing triggers automatic sending of letters', type: :feature do
  include MockAwsHelper
  include ActiveJob::TestHelper

  let(:tenancy_ref) { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
  let(:payment_ref) { Faker::Number.number(digits: 4) }
  let(:current_balance) { BigDecimal('525.00') }
  let!(:original_env_can_auto_letters) { ENV['CAN_AUTOMATE_LETTERS'] }
  let!(:original_env_patch_codes_letters) { ENV['PATCH_CODES_FOR_LETTER_AUTOMATION'] }
  let!(:original_env_can_auto_letter_one) { ENV['AUTOMATE_INCOME_COLLECTION_LETTER_ONE'] }
  let(:income_use_case_factory) { Hackney::Income::UseCaseFactory.new }
  let(:case_priority) { Hackney::Income::Models::CasePriority.last }
  let(:gov_notify_client) { double(Notifications::Client) }
  let(:fake_response) {
    OpenStruct.new(
      id: Faker::Number.number,
      reference: SecureRandom.uuid,
      postage: 'second'
    )
  }

  let(:allowed_jobs) { [Hackney::Income::Jobs::SyncCasePriorityJob, Hackney::Income::Jobs::SendLetterToGovNotifyJob] }

  before do
    mock_aws_client
    create_invalid_uh_records_for_an_income_letter(
      property_ref: Faker::Number.number(digits: 4),
      house_ref: Faker::Number.number(digits: 4),
      postcode: Faker::Address.postcode,
      leasedate: Time.zone.now.beginning_of_hour
    )
    mock_gov_notify_client

    ENV['CAN_AUTOMATE_LETTERS'] = 'true'
    ENV['AUTOMATE_INCOME_COLLECTION_LETTER_ONE'] = 'true'
    ENV['PATCH_CODES_FOR_LETTER_AUTOMATION'] = 'W02'
  end

  after do
    ENV['CAN_AUTOMATE_LETTERS'] = original_env_can_auto_letters
    ENV['PATCH_CODES_FOR_LETTER_AUTOMATION'] = original_env_patch_codes_letters
    ENV['AUTOMATE_INCOME_COLLECTION_LETTER_ONE'] = original_env_can_auto_letter_one
  end

  context 'when the cron job runs' do
    before do
      stub_action_diary_write(tenancy_ref: tenancy_ref, code: 'IC1', date: Time.zone.now)
    end

    context 'when a case with incomplete data exists' do
      it 'will not send the letter' do
        when_the_sync_runs(document_count_changes_by: 0, case_priority_count_changes_by: 1)
        then_the_case_priority_is(:send_letter_one)
        then_the_case_priority_is(:paused)
        then_there_is_a_paused_action_diary_entry
      end
    end
  end

  def given_a_case_exists
    income_use_case_factory.sync_case_priority.execute(tenancy_ref: tenancy_ref)
  end

  def when_the_sync_runs(document_count_changes_by:, case_priority_count_changes_by:)
    expect {
      expect {
        perform_enqueued_jobs(only: allowed_jobs) do
          TenancySync.new.perform
        end
      }.to change { Hackney::Cloud::Document.count }.by(document_count_changes_by)
    }.to change { Hackney::Income::Models::CasePriority.count }.by(case_priority_count_changes_by)
  end

  def when_the_tenancy_balance_in_uh_is(balance:)
    Hackney::UniversalHousing::Client.connection[:tenagree]
                                     .where(tag_ref: tenancy_ref)
                                     .update(cur_bal: balance)
  end

  def expect_case_priority_to_be(classification)
    expect(case_priority.tenancy_ref).to eq(tenancy_ref)
    expect(case_priority).to send("be_#{classification}".to_sym)
  end

  def mock_gov_notify_client
    stub_const('Notifications::Client', gov_notify_client)
    allow(gov_notify_client).to receive(:new).and_return(gov_notify_client)
    allow(gov_notify_client).to receive(:send_precompiled_letter).and_return(fake_response)
  end

  def then_there_is_a_paused_action_diary_entry
    expect(Hackney::UniversalHousing::Client.connection[:araction].count).to eq(1)
    action = Hackney::UniversalHousing::Client.connection[:araction].first
    expect(action[:action_code]).to eq(Hackney::Tenancy::ActionCodes::PAUSED_MISSING_DATA)
    errors = "'forename: missing mandatory field; surname: missing mandatory field'"
    expect(action[:action_comment]).to match(
      /Missing Data: Paused to \d{4}-\d{2}-\d{2}. Errors when generating Letter income_collection_letter_1: #{errors}/
    )
  end

  alias_method :given_a_case_priority_is, :expect_case_priority_to_be
  alias_method :then_the_case_priority_is, :expect_case_priority_to_be
  alias_method :when_there_is_a_case_with_invalid_data, :create_invalid_uh_records_for_an_income_letter
end
