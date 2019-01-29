require 'rails_helper'

describe Hackney::Income::Domain::NotificationReceipt do
  subject do
    described_class.new(body: body)
  end

  context 'with a nil body' do
    let(:body) { nil }

    it 'does not throw when body_without_newlines' do
      expect(subject.body_without_newlines).to eq(nil)
    end
  end

  context 'with a body that contains newlines' do
    let(:body) { "some body\n text with perhaps a \newline?" }

    it 'is stripped away with body_without_newlines' do
      expect(subject.body_without_newlines).to eq('some body text with perhaps a ewline?')
    end
  end
end
