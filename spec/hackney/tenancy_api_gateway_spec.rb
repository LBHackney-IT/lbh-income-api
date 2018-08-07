require 'rails_helper'

describe Hackney::Income::TenancyApiGateway do
  let(:gateway) { described_class.new(host: 'https://example.com') }

  context 'when retrieving tenancies' do
    subject { gateway.get_tenancies_by_refs(refs) }

    context 'and using a different host' do
      let(:gateway) { described_class.new(host: 'https://other.com') }
      let(:refs) { %w(123) }

      before do
        stub_request(:get, "https://other.com/api/v1/tenancies?tenancy_refs%5B%5D=123")
          .to_return(body: { 'tenancies' => [example_tenancy] }.to_json)
      end

      it 'should use the host' do
        subject
        expect(WebMock).to have_requested(:get, 'https://other.com/api/v1/tenancies?tenancy_refs%5B%5D=123').once
      end
    end

    context 'and passing no tenancy refs' do
      let(:refs) { [] }

      it 'should give no tenancies' do
        expect(subject).to be_empty
      end
    end

    context 'and the tenancy has a ref' do
      let(:refs) { %w(000015/01) }

      before do
        stub_request(:get, "https://example.com/api/v1/tenancies?tenancy_refs%5B%5D=000015/01")
          .to_return(body: { 'tenancies' => [example_tenancy] }.to_json)
      end

      it 'should give basic details on that tenancy' do
        expect(subject).to eq([{
          ref: '000015/01',
          current_balance: '£1000.00',
          current_arrears_agreement_status: '200',
          latest_action: {
            code: 'FBI',
            date: Time.parse('2018-10-01 12:30:00Z')
          },
          primary_contact: {
            name: 'Mr Fox Mulder',
            short_address: '123 Skinner Street',
            postcode: 'SP00KY'
          }
        }])
      end
    end

    context 'and the tenancy has nil values' do
      let(:refs) { %w(000017/01) }

      before do
        stub_request(:get, "https://example.com/api/v1/tenancies?tenancy_refs%5B%5D=000017/01")
          .to_return(body: { 'tenancies' => [example_tenancy_with_nils] }.to_json)
      end

      it 'should null out the values completely' do
        expect(subject).to eq([{
          ref: '000017/01',
          current_balance: '£19.99',
          current_arrears_agreement_status: nil,
          latest_action: nil,
          primary_contact: nil
        }])
      end
    end

    context 'and two tenancy refs are given' do
      let(:refs) { %w(000015/01 000017/01) }

      before do
        stub_request(:get, "https://example.com/api/v1/tenancies?tenancy_refs%5B%5D=000017/01&tenancy_refs%5B%5D=000015/01")
          .to_return(body: { 'tenancies' => [example_tenancy, example_tenancy_with_nils] }.to_json)
      end

      it 'should include both tenancies' do
        expect(subject.count).to eq(2)
      end

      it 'should return them in order' do
        ordered_refs = subject.map { |t| t.fetch(:ref) }
        expect(ordered_refs).to eq(['000015/01', '000017/01'])
      end
    end
  end

  def example_tenancy
    {
      'ref' => '000015/01',
      'current_balance' => '£1000.00',
      'current_arrears_agreement_status' => '200',
      'latest_action' => {
        'code' => 'FBI',
        'date' => '2018-10-01 12:30:00Z'
      },
      'primary_contact' => {
        'name' => 'Mr Fox Mulder',
        'short_address' => '123 Skinner Street',
        'postcode' => 'SP00KY'
      }
    }
  end

  def example_tenancy_with_nils
    {
      'ref' => '000017/01',
      'current_balance' => '£19.99',
      'current_arrears_agreement_status' => nil,
      'latest_action' => {
        'code' => nil,
        'date' => '0001-01-01 00 => 00 => 00Z'
      },
      'primary_contact' => {
        'name' => nil,
        'short_address' => nil,
        'postcode' => nil
      }
    }
  end
end
