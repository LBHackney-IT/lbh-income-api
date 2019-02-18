namespace :cloud do
  desc 'Upload a Document to the cloud (Aws S3) and keep track of it in internal table'
  task :save, [:filename] do |_task, args|
    puts 'Saving to the cloud'

    response = Document.cloud_save(args.filename)

    if response.errors.empty?
      puts 'File successfully saved.'
    else
      puts "Errors: #{response.inspect}"
    end
  end
end
