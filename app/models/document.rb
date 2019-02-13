class Document < ApplicationRecord
  HACKNEY_BUCKET_DOCS = 'hackney-docs'.freeze

  validates :filename, :uuid, presence: true
  validates :filename, :uuid, uniqueness: true

  def self.cloud_save(filename)
    uuid = SecureRandom.uuid
    format = File.extname(filename)
    new_filename = "#{uuid}.#{format}"
    new_doc = Document.create(filename: filename,
                              uuid: uuid,
                              format: format,
                              mime_type: Rack::Mime.mime_type(format))

    cloud_storage.save(HACKNEY_BUCKET_DOCS, filename, new_filename) if new_doc.errors.empty?
  end

  def self.cloud_storage
    Rails.configuration.cloud_storage
  end
end
