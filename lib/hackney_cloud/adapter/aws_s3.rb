module HackneyCloud
  module Adapter
    class AwsS3
      def initialize(stub: false)
        client = Aws::S3::Client.new(region: 'eu-west-2', stub_responses: stub)

        @s3 = Aws::S3::Resource.new(client: client)
      end

      def upload(bucketname, filename)
        name = File.basename filename
        obj = @s3.bucket(bucketname).object(name)

        obj.upload_file(filename)
      end
    end
  end
end
