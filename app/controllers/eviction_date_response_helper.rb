module EvictionDateResponseHelper
  def map_eviction_date_to_response(eviction_date:)
    {
      id: eviction_date.id,
      tenancyRef: eviction_date.tenancy_ref,
      evictionDate: eviction_date.eviction_date
    }
  end
end
