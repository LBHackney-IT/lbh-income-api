namespace :cloud do
  desc 'Upload a Document to the cloud and keep track of it in Cloud::Document table'
  task :save, [:filename] do |_task, args|
    puts 'Saving to the cloud'

    storage = Hackney::Cloud::Storage.new(Rails.configuration.cloud_adapter, Hackney::Cloud::Document)
    response = storage.save(args[:filename])

    if response[:errors].empty?
      puts 'File successfully saved.'
    else
      puts "Errors: #{response.inspect}"
    end
  end

  desc 'Cloud Storage Statistic'
  task :stats do
    puts '- - - Cloud Storage Statistic - - -'

    puts "Total number of uploaded Documents: #{total_number_of_uploads}"
    puts "Succefully uploaded:                #{number_of_uploads 'uploaded'}"
    puts "Failed or in progress:              #{number_of_uploads 'uploading'}"

    print_last_upload
  end

  private

  def number_of_uploads(status = nil)
    Hackney::Cloud::Document.where(status: status).count
  end

  def total_number_of_uploads
    Hackney::Cloud::Document.count
  end

  def print_last_upload
    last_upload = Hackney::Cloud::Document.last

    if last_upload.present?
      puts '- - - Last document upload - - -'
      last_upload.attributes.each do |e|
        puts "    #{e[0]}: #{e[1]}"
      end
    else
      puts 'No documents uploaded!'
    end
  end
end
