module Hackney
  module Cloud
    module Adapter
      class AwsS3
        def initialize(encryption_client)
          @client = encryption_client
        end

        def upload(bucket_name:, binary_letter_content:, filename:)
          # Add encrypted item to bucket
          response = client.put_object(
            body: binary_letter_content,
            bucket: bucket_name,
            key: filename
          )

          parse_response_context(response)
        end

        def download(bucket_name:, filename:)
          response = client.get_object(bucket: bucket_name, key: filename)
          convert_response_to_tempfile(filename: filename, response: response)
          rescue Aws::S3::Errors::NoSuchKey => e
            puts e.inspect
        end

        private

        attr_reader :client

        def convert_response_to_tempfile(filename:, response:)
          tempfile = Tempfile.open(filename, 'tmp/')
          tempfile.binmode

          tempfile.write response.body.read
          tempfile.rewind
          tempfile
        end

        def parse_response_context(response)
          http_request_context = response.context.http_request
          uploaded_at = Time.parse(http_request_context.headers['x-amz-date'])
          url = http_request_context.endpoint

          { url: url, uploaded_at: uploaded_at }
        end

        def customer_managed_key
          Rails.application.config_for('cloud_storage')['customer_managed_key']
        end
      end
    end
  end
end
