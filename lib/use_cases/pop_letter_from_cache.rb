module UseCases
  class PopLetterFromCache
    def initialize(cache:)
      @cache = cache
    end

    def execute(uuid:)
      letter_data = @cache.read(uuid)
      @cache.delete(uuid)
      letter_data
    end
  end
end
