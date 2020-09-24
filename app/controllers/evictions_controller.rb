class EvictionsController < ApplicationController
  include EvictionResponseHelper
  def index
    requested_eviction = income_use_case_factory.view_evictions.execute(tenancy_ref: params.fetch(:tenancy_ref))

    evictions = requested_eviction.map do |e|
      map_eviction_to_response(eviction: e)
    end

    response = { evictions: evictions }
    render json: response
  end

  def create
    parameters = %i[tenancy_ref date].freeze

    create_eviction_params = params.permit(parameters)

    eviction_params = {
      tenancy_ref: create_eviction_params[:tenancy_ref],
      date: create_eviction_params[:date]
    }

    new_eviction = income_use_case_factory.create_eviction_and_sync.execute(eviction_params: eviction_params)
    response = map_eviction_to_response(eviction: new_eviction)

    render json: response
  end
end
