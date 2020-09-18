class EvictionDatesController < ApplicationController
  include EvictionDateResponseHelper
  def index
    requested_eviction_date = income_use_case_factory.view_eviction_dates.execute(tenancy_ref: params.fetch(:tenancy_ref))

    dates = requested_eviction_date.map do |e|
      map_eviction_date_to_response(eviction_date: e)
    end

    response = { evictionDates: dates }
    render json: response
  end

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
