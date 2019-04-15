FactoryBot.define do
  factory :document, class: Hackney::Cloud::Document do
    uuid { SecureRandom.uuid }
    mime_type { 'application/pdf' }
    extension { '.pdf' }

    ext_message_id { SecureRandom.uuid }
    status { 'uploaded' }
  end
end
