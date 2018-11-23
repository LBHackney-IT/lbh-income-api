class ActionDiaryController < ApplicationController
  REQUIRED_PARAMS = %i[tenancy_ref action_code action_balance comment user_id].freeze

  def create
    begin
      income_use_case_factory.add_action_diary.execute(action_diary_params.to_h)
    rescue ArgumentError => e
      render(json: { status: 'error', code: 422, message: e.message }, status: :unprocessable_entity) && (return)
    end
    head(:no_content)
  end

  def action_diary_params
    params.require(REQUIRED_PARAMS)
    allowed_params = params.permit(REQUIRED_PARAMS)

    allowed_params[:action_balance] = allowed_params[:action_balance].to_f
    allowed_params[:user_id] = allowed_params[:user_id].to_i

    allowed_params
  end
end
