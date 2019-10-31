require 'rails_helper'

describe Hackney::Income::SetTenancyPausedStatus do
  subject { described_class.new(gateway: PauseGatewayDouble.new, add_action_diary_usecase: action_diary_gateway) }

  let(:action_diary_gateway) { double(Hackney::Tenancy::Gateway::ActionDiaryGateway) }

  let(:tenancy_ref) { Faker::Lorem.characters(8) }
  let(:future_date) { Faker::Date.forward(23).to_s }
  let(:pause_reason) { Faker::Lorem.sentence }
  let(:pause_comment) { Faker::Lorem.paragraph }
  let(:username) { Faker::Name.name }
  let(:action_code) { Faker::Internet.slug }

  before do
    allow(action_diary_gateway).to receive(:execute)
  end

  context 'when setting the pause status for a case' do
    context 'with the operation being successful' do
      it 'passes the required params to the gateway' do
        expect_any_instance_of(PauseGatewayDouble).to receive(:set_paused_until)
          .with(
            tenancy_ref: tenancy_ref,
            until_date: future_date,
            pause_reason: pause_reason,
            pause_comment: pause_comment
          )

        subject.execute(
          username: username,
          action_code: action_code,
          tenancy_ref: tenancy_ref,
          until_date: future_date,
          pause_reason: pause_reason,
          pause_comment: pause_comment
        )
      end
    end

    context 'when the operation is unsuccessful' do
      subject { described_class.new(gateway: PauseGatewayDouble.new(true), add_action_diary_usecase: action_diary_gateway) }

      it 'catches the exception raised when the tenancy ref is not found' do
        expect do
          subject.execute(
            username: username,
            action_code: action_code,
            tenancy_ref: tenancy_ref,
            until_date: future_date,
            pause_reason: pause_reason,
            pause_comment: pause_comment
          )
        end.to raise_error
          .with_message(/#{tenancy_ref}/)
      end
      it 'catches the exception raised when the date is not valid' do
        expect do
          subject.execute(
            username: username,
            action_code: action_code,
            tenancy_ref: tenancy_ref,
            until_date: 'future_date',
            pause_reason: pause_reason,
            pause_comment: pause_comment
          )
        end.to raise_error
          .with_message(/invalid date/)
      end
    end
  end
end

class PauseGatewayDouble
  def initialize(raise_exc = false)
    @raise = raise_exc
  end

  def set_paused_until(tenancy_ref:, until_date:, pause_reason:, pause_comment:)
    Date.parse(until_date)
    raise "Raised on #{tenancy_ref}" if @raise
  end
end
