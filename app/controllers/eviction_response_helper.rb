module EvictionResponseHelper
  def map_eviction_to_response(eviction:)
    {
      id: eviction.id,
      tenancyRef: eviction.tenancy_ref,
      date: eviction.date
    }
  end
end
