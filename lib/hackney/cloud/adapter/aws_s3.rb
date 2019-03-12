module Hackney
  module Cloud
    module Adapter
      class AwsS3
        def initialize(encryption_client)
          @client = encryption_client
        end

        def upload(bucket_name:, filename:, new_filename:)
          content = File.read(filename)

          # Add encrypted item to bucket
          resp = client.put_object(
            body: content,
            bucket: bucket_name,
            key: new_filename
          )

          resp.successful? || raise('Cloud Storage Error!')
        end

        def download(bucket_name, filename)
          client.get_object(bucket: bucket_name, key: filename)
        end

        private

        attr_reader :client

        def customer_managed_key
          Rails.application.config_for('cloud_storage')['customer_managed_key']
        end
      end
    end
  end
end
