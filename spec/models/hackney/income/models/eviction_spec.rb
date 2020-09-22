require 'rails_helper'

describe Hackney::Income::Models::Eviction, type: :model do
  it 'includes the fields for a eviction' do
    eviction = described_class.new
    expect(eviction.attributes).to include(
      'tenancy_ref',
      'date'
    )
  end

  it { is_expected.to validate_presence_of(:tenancy_ref) }
  it { is_expected.to validate_presence_of(:date) }
end
