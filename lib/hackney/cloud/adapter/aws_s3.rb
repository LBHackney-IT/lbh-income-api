module Hackney
  module Cloud
    module Adapter
      class AwsS3
        def initialize(stub: false)
          client = Aws::S3::Client.new(stub_responses: stub)

          @s3 = Aws::S3::Resource.new(client: client)
        end

        def upload(bucketname, filename, new_filename)
          s3_file_obj = @s3.bucket(bucketname).object(new_filename)

          success = s3_file_obj.upload_file(filename)

          success ? "#{s3_file_obj.public_url}/#{new_filename}" : nil
        end
      end
    end
  end
end
