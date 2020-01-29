class ActionDiaryController < ApplicationController
  REQUIRED_PARAMS = %i[tenancy_ref action_code comment username].freeze

  def create
    begin
      income_use_case_factory.add_action_diary_and_pause_case.execute(
        tenancy_ref: action_diary_params.fetch(:tenancy_ref),
        action_code: action_diary_params.fetch(:action_code),
        comment: action_diary_params.fetch(:comment),
        username: action_diary_params.fetch(:username)
      )
    rescue ArgumentError => e
      render(json: { status: 'error', code: 422, message: e.message }, status: :unprocessable_entity)
      return
    end

    head(:no_content)
  end

  def action_diary_params
    params.require(REQUIRED_PARAMS)
    allowed_params = params.permit(REQUIRED_PARAMS)

    allowed_params[:username] = allowed_params[:username]

    allowed_params
  end
end
