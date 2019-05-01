require 'rails_helper'

describe Hackney::Notification::ManualActionCode do
  let(:template_name) { '' }

  describe '#get_by_sms_template_name' do
    let(:subject) { described_class.get_by_sms_template_name(template_name: template_name) }

    context 'When name starts with Green' do
      let(:template_name) { 'Green arrears reminder' }
      it { should eq(Hackney::Tenancy::ActionCodes::MANUAL_GREEN_SMS_ACTION_CODE) }
    end

    context 'When name starts with Amber' do
      let(:template_name) { 'Amber arrears reminder' }
      it { should eq(Hackney::Tenancy::ActionCodes::MANUAL_AMBER_SMS_ACTION_CODE) }
    end

    context 'When name starts with with an unknown word' do
      let(:template_name) { 'Arrears reminder' }
      it { should eq(Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE) }

      context 'With Green in the name' do
        let(:template_name) { 'Arrears Green reminder' }
        it { should eq(Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE) }
      end

      context 'With Amber in the name' do
        let(:template_name) { 'Arrears Amber reminder' }
        it { should eq(Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE) }
      end
    end
  end
end
