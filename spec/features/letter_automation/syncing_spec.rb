require 'rails_helper'
require 'notifications/client'
require 'schedules/tenancy_sync'

describe 'syncing triggers automatic sending of letters', type: :feature do
  include MockAwsHelper
  include ActiveJob::TestHelper

  let(:tenancy_ref) { "#{Faker::Number.number(6)}/#{Faker::Number.number(2)}" }
  let(:payment_ref) { Faker::Number.number(4) }
  let(:current_balance) { BigDecimal('525.00') }
  let(:income_use_case_factory) { Hackney::Income::UseCaseFactory.new }
  let(:case_priority) { Hackney::Income::Models::CasePriority.last }
  let(:gov_notify_client) { double(Notifications::Client) }
  let(:allowed_jobs) { [Hackney::Income::Jobs::SyncCasePriorityJob, Hackney::Income::Jobs::SendLetterToGovNotifyJob] }

  let!(:original_env_can_auto_letters) { ENV['CAN_AUTOMATE_LETTERS'] }
  let!(:original_env_patch_codes_letters) { ENV['PATCH_CODES_FOR_LETTER_AUTOMATION'] }
  let!(:original_env_can_auto_letter_one) { ENV['AUTOMATE_INCOME_COLLECTION_LETTER_ONE'] }

  before do
    mock_aws_client
    create_valid_uh_records_for_an_income_letter(
      property_ref: Faker::Number.number(4),
      house_ref: Faker::Number.number(4),
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

    it 'will sync the case priority, send the letter automatically and pause case until next sync' do
      Timecop.freeze(Date.yesterday)

      when_the_sync_runs(document_count_changes_by: 1, case_priority_count_changes_by: 1)
      then_a_document_is_queued
      then_the_case_priority_is_paused_until_tomorrow
      then_the_case_priority_is(:send_letter_one)

      Timecop.return

      when_the_sync_runs(document_count_changes_by: 0, case_priority_count_changes_by: 0)
      case_priority.reload
      then_the_case_priority_is(:no_action)
    end

    context 'when a tenant has no arrears balance' do
      let(:current_balance) { 0 }

      it 'will automatically send letter one when the tenant enters arrears' do
        given_a_case_exists
        when_the_case_priority_is(:no_action)
        when_the_tenancy_balance_in_uh_is(balance: 350)
        when_the_sync_runs(document_count_changes_by: 1, case_priority_count_changes_by: 0)
        then_a_document_is_queued
        then_the_case_priority_is(:no_action)
      end
    end

    context 'when the flag for letter 1 automation is false' do
      before do
        ENV['AUTOMATE_INCOME_COLLECTION_LETTER_ONE'] = 'false'
      end

      it 'will not automatically send letter one' do
        when_the_sync_runs(document_count_changes_by: 0, case_priority_count_changes_by: 1)
        then_the_case_priority_is(:send_letter_one)
      end
    end

    context 'when automation is turned off' do
      before do
        ENV['CAN_AUTOMATE_LETTERS'] = 'false'
      end

      it 'will not automatically send letter one' do
        when_the_sync_runs(document_count_changes_by: 0, case_priority_count_changes_by: 1)
        then_the_case_priority_is(:send_letter_one)
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

  def then_the_case_priority_is(classification)
    expect(case_priority.tenancy_ref).to eq(tenancy_ref)
    expect(case_priority).to send("be_#{classification}".to_sym)
  end

  def then_the_case_priority_is_paused_until_tomorrow
    expect(case_priority.paused?).to eq(true)
    expect(case_priority.is_paused_until).to eq(Date.tomorrow)
  end

  def then_a_document_is_queued
    document = Hackney::Cloud::Document.last
    expect(JSON.parse(document.metadata)['payment_ref']).to eq(payment_ref)
    expect(document).to be_queued
  end

  def mock_gov_notify_client
    stub_const('Notifications::Client', gov_notify_client)
    allow(gov_notify_client).to receive(:new).and_return(gov_notify_client)
    allow(gov_notify_client)
      .to receive(:send_precompiled_letter)
      .and_return(
        OpenStruct.new(
          id: Faker::Number.number,
          reference: SecureRandom.uuid,
          postage: 'second'
        )
      )
  end

  alias_method :when_the_case_priority_is, :then_the_case_priority_is
end
