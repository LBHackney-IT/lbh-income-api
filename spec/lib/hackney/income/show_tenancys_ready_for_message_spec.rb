require 'rails_helper'

describe Hackney::Income::ShowTenancysReadyForMessage do
  let(:tenancies_ready_for_message_gateway) { instance_double(Hackney::Income::SqlsTenanciesReadyForMessageGateway) }

  let(:show_tenancies_ready_for_message) do
    described_class.new(
      tenancies_ready_for_message_gateway: tenancies_ready_for_message_gateway
    )
  end

  subject { show_tenancies_ready_for_message.execute }

  context 'when asking for a list of tennacys to send messages to' do
    it 'should call its gateway' do
      expect(tenancies_ready_for_message_gateway).to receive(:get_message_level_1_tenancies)
      subject
    end

    it 'should return results from the gateway' do
      expect(tenancies_ready_for_message_gateway).to(
        receive(:get_message_level_1_tenancies)
        .and_return(results: 'these')
      )
      expect(subject).to eq(results: 'these')
    end
  end
end
