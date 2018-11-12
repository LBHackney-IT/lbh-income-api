require 'rails_helper'

describe Hackney::Income::ShowTenanciesForMessageOne do
  let(:sql_tenancies_for_messages_gateway) { instance_double(Hackney::Income::SqlTenanciesForMessagesGateway) }

  let(:show_tenancies_for_message_1) do
    described_class.new(
      sql_tenancies_for_messages_gateway: sql_tenancies_for_messages_gateway
    )
  end

  subject { show_tenancies_for_message_1.execute }

  context 'when asking for a list of tennacys to send messages to' do
    it 'should call its gateway' do
      expect(sql_tenancies_for_messages_gateway).to receive(:get_tenancies_for_message_1)
      subject
    end

    it 'should return results from the gateway' do
      expect(sql_tenancies_for_messages_gateway).to(
        receive(:get_tenancies_for_message_1)
        .and_return(results: 'these')
      )
      expect(subject).to eq(results: 'these')
    end
  end
end
