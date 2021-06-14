require 'rails_helper'

describe Hackney::UniversalHousing::Client do
  subject(:uh_client) { described_class.connection }

  it 'to be a Sequel database instance' do
    expect(uh_client).to be_a(Sequel::TinyTDS::Database)
  end

  it 'can execute queries against the database' do
    expect(uh_client.table_exists?('MATenancyAgreement')).to be(true)
  end
end
