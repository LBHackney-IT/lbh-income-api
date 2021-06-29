module Hackney
  module Cloud
    class EncryptionClient
      attr_writer :kms_key_id

      def initialize(customer_managed_key)
        self.kms_key_id = customer_managed_key
      end

      def create
        Aws::S3::Client.new
      end

      private

      attr_reader :kms_key_id

      def kms_client
        Aws::KMS::Client.new
      end

      def client
        Aws::S3::Client.new
      end
    end
  end
end
