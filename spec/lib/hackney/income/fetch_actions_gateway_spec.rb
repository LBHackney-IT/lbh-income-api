require 'rails_helper'

describe Hackney::Income::FetchActionsGateway do
  let(:gateway) { described_class.new }

  let(:action_model) { Hackney::IncomeCollection::Action }

  context 'when retrieving actions' do
    subject { gateway.get_actions }

    before do
      create(:leasehold_action)
    end

    context 'when there is an action' do
      it 'retrieves the action' do
        expect(subject.count).to eq(1)
      end

      it { expect(subject.first).to be_a action_model }
    end

    context 'with page number set to one and number per page set to two' do
      subject { gateway.get_actions(page_number: 1, number_per_page: 2) }

      before do
        create_list(:leasehold_action, 4)
      end

      it 'only returns the first two' do
        expect(subject.count).to eq(2)
      end
    end
  end
end
