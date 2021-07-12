module Hackney
  module Cloud
    class DownloadEncryptionClient
      attr_writer :kms_key_id

      def initialize(customer_managed_key)
        self.kms_key_id = customer_managed_key
      end

      def create
        Aws::S3::Encryption::Client.new(
          kms_key_id: kms_key_id,
          kms_client: kms_client,
          client: client
        )
      end

      private

      attr_reader :kms_key_id

      def kms_client
        Aws::KMS::Client.new(
          access_key_id: ENV['OLD_ACCOUNT_ACCESS_KEY_ID'],
          secret_access_key: ENV['OLD_ACCOUNT_SECRET_ACCESS_KEY']
        )
      end

      def client
        Aws::S3::Client.new(
          access_key_id: ENV['OLD_ACCOUNT_ACCESS_KEY_ID'],
          secret_access_key: ENV['OLD_ACCOUNT_SECRET_ACCESS_KEY']
        )
      end

    end
  end
end
