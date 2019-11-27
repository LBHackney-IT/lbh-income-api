require 'rails_helper'

describe Hackney::PDF::GetTemplatesForUser do
  subject do
    described_class.new
  end

  let(:test_template) {
    {
      id: 'test_template',
      name: 'Test template',
      path: 'spec/lib/hackney/pdf/test_template.erb'
    }
  }

  let(:user_groups) { ['some-user-group'] }

  let(:user) {
    Hackney::Domain::User.new.tap do |u|
      u.id = 1
      u.name = Faker::Name.name
      u.email = Faker::Internet.email
      u.groups = user_groups
    end
  }

  context 'when getting the template directory paths for the user' do
    let(:leasehold_path) { Hackney::PDF::GetTemplatesForUser::LEASEHOLD_SERVICES_TEMPLATE_DIRECTORY_PATH }
    let(:income_path) { Hackney::PDF::GetTemplatesForUser::INCOME_COLLECTION_TEMPLATE_DIRECTORY_PATH }

    it 'checks the leasehold template path exists' do
     expect(Pathname.new(leasehold_path)).to exist
  end

    it 'checks the income template path exists' do
      expect(Pathname.new(income_path)).to exist
    end
  end

  context 'when user is in the leasehold services group' do
    let(:user_groups) { ['leasehold-group'] }

    it 'templates are found in the correct directory' do
      allow(Dir).to receive(:glob)
        .with(["#{Hackney::PDF::GetTemplatesForUser::LEASEHOLD_SERVICES_TEMPLATE_DIRECTORY_PATH}*.erb"])
        .and_return([test_template[:path]])

      expect(subject.execute(user: user))
        .to eq([test_template])
    end
  end

  context 'when user is in the income collection group' do
    let(:user_groups) { ['income-group'] }

    it 'templates are found in the correct directory' do
      allow(Dir).to receive(:glob)
        .with(["#{Hackney::PDF::GetTemplatesForUser::INCOME_COLLECTION_TEMPLATE_DIRECTORY_PATH}*.erb"])
        .and_return([test_template[:path]])

      expect(subject.execute(user: user))
        .to eq([test_template])
    end
  end

  context 'when user is in the income collection and leasehold services group' do
    let(:user_groups) { ['leasehold-group', 'income-group'] }

    it 'templates are found in the correct directory' do
      allow(Dir).to receive(:glob)
        .with([
          "#{Hackney::PDF::GetTemplatesForUser::LEASEHOLD_SERVICES_TEMPLATE_DIRECTORY_PATH}*.erb",
          "#{Hackney::PDF::GetTemplatesForUser::INCOME_COLLECTION_TEMPLATE_DIRECTORY_PATH}*.erb"
        ])
        .and_return([test_template[:path]])

      expect(subject.execute(user: user)).to eq([test_template])
    end
  end

  context 'when user is not in any appropriate group' do
    it 'no templates are found' do
      expect(subject.execute(user: user)).to eq([])
    end
  end
end
