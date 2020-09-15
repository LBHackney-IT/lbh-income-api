require 'rails_helper'

describe Hackney::Income::Models::EvictionDate, type: :model do

  it 'includes the fields for a eviction date' do
    eviction_date = described_class.new
    expect(eviction_date.attributes).to include(
      'tenancy_ref',
      'eviction_date'
    )
  end

  it { is_expected.to validate_presence_of(:tenancy_ref) }
end
