require 'rails_helper'

describe Hackney::Income::SqlPauseTenancyGateway do
  let(:tenancy_1) { create_tenancy_model }
  let(:pause_reason) { Faker::Lorem.sentence }
  let(:pause_comment) { Faker::Lorem.paragraph }
  let(:future_date) { Faker::Time.forward(23).iso8601 }
  let(:invalid_string) { SecureRandom.uuid }
  let(:gateway_model) { described_class::GatewayModel }

  subject { described_class.new }

  before do
    tenancy_1.save
  end

  context 'set pause status' do
    context 'when the tenancy does not exist' do
      it 'should raise an exception containing the tenancy ref' do
        expect do
          subject.set_paused_until(
            tenancy_ref: invalid_string,
            until_date: future_date,
            pause_reason: pause_reason,
            pause_comment: pause_comment
          )
        end
          .to raise_error
          .with_message(/#{invalid_string}/)
      end
    end

    context 'when the date given can not be parsed' do
      it 'should raise an exception containing date error' do
        expect do
          subject.set_paused_until(
            tenancy_ref: tenancy_1.tenancy_ref,
            until_date: invalid_string,
            pause_reason: pause_reason,
            pause_comment: pause_comment
          )
        end
          .to raise_error
          .with_message(/#{invalid_string}/)
      end
    end

    it 'should default to unpaused' do
      expect(tenancy_1.paused?).to be(false)
    end

    it 'should update with the given an unpause date' do
      subject.set_paused_until(
        tenancy_ref: tenancy_1.tenancy_ref,
        until_date: future_date,
        pause_reason: pause_reason,
        pause_comment: pause_comment
      )

      expect(gateway_model.find_by(tenancy_ref: tenancy_1.tenancy_ref).paused?).to be(true)
    end
  end

  context 'get tenancy pause' do
    it 'should get tenancy pause' do
      tenancy_pause = subject.get_tenancy_pause(
        tenancy_ref: tenancy_1.tenancy_ref
      )

      expect(tenancy_pause).to eq(tenancy_1)
    end
  end
end
