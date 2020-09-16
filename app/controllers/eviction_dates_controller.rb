class EvictionDatesController < ApplicationController
  include EvictionDateResponseHelper
  def create
    parameters = %i[tenancy_ref eviction_date].freeze

    create_eviction_date_params = params.permit(parameters)

    eviction_date_params = {
      tenancy_ref: create_eviction_date_params[:tenancy_ref],
      eviction_date: create_eviction_date_params[:eviction_date]
    }

    new_eviction_date = income_use_case_factory.create_eviction_date.execute(eviction_date_params: eviction_date_params)
    response = map_eviction_date_to_response(eviction_date: new_eviction_date)

    render json: response
  end
end
