module Hackney
  module Cloud
    class Storage
      def initialize(storage_adapter)
        @storage_adapter = storage_adapter
      end

      def save(bucket_name, filename, new_filename)
        @storage_adapter.upload(bucket_name, filename, new_filename)
      end
    end
  end
end
