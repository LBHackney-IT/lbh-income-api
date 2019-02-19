module Hackney
  class CloudDocument < ApplicationRecord
    HACKNEY_BUCKET_DOCS = 'hackney-docs'.freeze

    validates :filename, :uuid, presence: true

    def self.cloud_save(filename)
      raise "No such file: #{filename}" unless File.exist?(filename)

      uuid = SecureRandom.uuid
      extension = File.extname(filename)
      new_filename = "#{uuid}#{extension}"

      new_doc = create(filename: filename,
                       uuid: uuid,
                       extension: extension,
                       mime_type: Rack::Mime.mime_type(extension))

      if new_doc.errors.empty?
        url = cloud_storage.save(HACKNEY_BUCKET_DOCS, filename, new_filename)
        new_doc.update(url: url)
      end

      { errors: new_doc.errors.full_messages }
    end

    def self.cloud_storage
      Rails.configuration.cloud_storage
    end
  end
end
