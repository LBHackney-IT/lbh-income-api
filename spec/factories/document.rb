FactoryBot.define do
  factory :document, class: Hackney::Cloud::Document do
    uuid { SecureRandom.uuid }
    ext_message_id { SecureRandom.uuid }
    status { 'uploaded' }
  end
end
