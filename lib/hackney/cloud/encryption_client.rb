module Hackney
  module Cloud
    class EncryptionClient
      def initialize(customer_managed_key)
        @customer_managed_key = customer_managed_key
      end

      def create
        kms = Aws::KMS::Client.new

        Aws::S3::Encryption::Client.new(
          kms_key_id: @customer_managed_key,
          kms_client: kms
        )
      end
    end
  end
end
