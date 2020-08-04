class ActionsController < ApplicationController
  REQUIRED_INDEX_PARAMS = %i[service_area_type].freeze

  def index
    response = income_use_case_factory.fetch_actions.execute(
      page_number: actions_params[:page_number],
      number_per_page: actions_params[:number_per_page],
      service_area_type: actions_params[:service_area_type],
      filters: {
        is_paused: actions_params[:is_paused],
        pause_reason: actions_params[:pause_reason],
        classification: actions_params[:recommended_actions],
        patch: actions_params[:patch],
        full_patch: actions_params[:full_patch]
      }
    )

    render json: response
  end

  def actions_params
    params.require(REQUIRED_INDEX_PARAMS)
    allowed_params = params.permit(REQUIRED_INDEX_PARAMS + %i[
      page_number number_per_page pause_reason
      is_paused patch recommended_actions full_patch
    ])

    allowed_params[:is_paused] = ActiveModel::Type::Boolean.new.cast(allowed_params[:is_paused])
    allowed_params[:full_patch] = ActiveModel::Type::Boolean.new.cast(allowed_params[:full_patch])

    allowed_params[:page_number] = min_1(allowed_params[:page_number].to_i)
    allowed_params[:number_per_page] = min_10(allowed_params[:number_per_page].to_i)

    allowed_params[:pause_reason] = allowed_params.fetch(:pause_reason, nil)

    allowed_params
  end

  def min_1(number)
    [1, number].max
  end

  def min_10(number)
    [10, number].max
  end
end
