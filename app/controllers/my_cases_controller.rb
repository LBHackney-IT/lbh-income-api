class MyCasesController < ApplicationController
  REQUIRED_INDEX_PARAMS = %i[user_id page_number number_per_page].freeze

  def index
    response = income_use_case_factory.view_my_cases.execute(
      user_id: my_cases_params[:user_id],
      page_number: my_cases_params[:page_number],
      number_per_page: my_cases_params[:number_per_page],
      filters: {
        is_paused: my_cases_params[:is_paused],
        classification: my_cases_params[:recommended_actions],
        patch: my_cases_params[:patch]
      }
    )

    render json: response
  end

  def my_cases_params
    params.require(REQUIRED_INDEX_PARAMS)
    allowed_params = params.permit(REQUIRED_INDEX_PARAMS + %i[is_paused patch recommended_actions])

    allowed_params[:user_id] = allowed_params[:user_id].to_i

    allowed_params[:is_paused] = ActiveModel::Type::Boolean.new.cast(allowed_params[:is_paused])

    allowed_params[:page_number] = min_1(allowed_params[:page_number].to_i)
    allowed_params[:number_per_page] = min_1(allowed_params[:number_per_page].to_i)

    allowed_params
  end

  def min_1(number)
    [1, number].max
  end

  def sync
    income_use_case_factory.schedule_sync_cases.execute
    render json: { success: true }
  end
end
