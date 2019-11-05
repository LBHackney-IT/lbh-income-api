module UseCases
  class SaveToCache
    def initialize(cache:)
      @cache = cache
    end

    def execute(data:)
      cache_key = SecureRandom.uuid

      @cache.write(cache_key, data, expires_in: 12.hours)

      cache_key
    end
  end
end
