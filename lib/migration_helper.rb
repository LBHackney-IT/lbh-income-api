module MigrationHelper
  module Console
    def migrate_docs()
      puts 'Processing downloads'
      document_model = Hackney::Cloud::Document
      docs = document_model.all
      total_docs = docs.count
      count = 1
      header = "record_id,file_name,outcome"
      write_to_file(header)
      puts "total documents to process: #{total_docs}"
      # docs.each do |doc|
      #   puts "migrating document #{doc[:id]} - #{count} of #{total_docs}"
      #   result = migrate_doc(doc)
      #   row = "#{doc[:id]},#{doc[:uuid]}#{doc[:extension]},#{result}"
      #   write_to_file(row)
      #   puts "#{doc[:id]} done - #{((count*100)/total_docs).to_i}% completed"
      #   count += 1
      # end
      migrate_doc(document_model.find_by(id: '16439'))
      "Process complete"
    end


    private
    def migrate_doc(doc)
      cloud_gateway = Rails.configuration.cloud_adapter
      doc_download = download.execute(id: doc[:id])
      if  File.exists?(doc_download[:filepath])
        content = File.open(doc_download[:filepath], "rb")
        pdf = content.read
        response = cloud_gateway.upload(
          filename: doc_download[:document][:filename],
          bucket_name: Rails.application.config_for('cloud_storage')['bucket_docs'],
          binary_letter_content: pdf
        )
        File.delete(doc_download[:filepath])
        return 'Success'
      end
      rescue Aws::S3::Errors::ServiceError => e
        handle_exception(doc, e)
      rescue Aws::S3::Errors::NoSuchKey => e
        handle_exception(doc, e)
      rescue Exception => e
        handle_exception(doc, e)
    end

    def handle_exception(doc, error)
      row = "#{doc[:id]},#{doc[:uuid]}#{doc[:extension]},#{error.message}"
      write_to_file(row)
      puts error.message
    end

    def download
      Hackney::Letter::DownloadUseCase.new(
        download_storage
      )
    end

    def write_to_file(row)
      file = "tmp/results.csv"
      File.open(file, "a") do |csv|
        csv << row
        csv << "\n"
      end
    end

    def cloud_storage
      Hackney::Cloud::Storage.new(Rails.configuration.cloud_adapter, Hackney::Cloud::Document)
    end

    def download_storage
      Hackney::Cloud::DownloadStorage.new(Rails.configuration.download_adapter, Hackney::Cloud::Document)
    end
  end
end
