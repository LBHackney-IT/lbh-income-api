module HackneyCloud
  class Storage
    def initialize(storage_adapter)
      @storage_adapter = storage_adapter
    end

    def save(bucket_name, filename)
      @storage_adapter.upload(bucket_name, filename)
    end
  end
end
