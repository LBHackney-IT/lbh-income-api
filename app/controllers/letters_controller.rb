require "#{Rails.root}/lib/hackney/service_charge/exceptions/service_charge_exception"
require 'hackney/income/universal_housing_leasehold_gateway.rb'

class LettersController < ApplicationController
  def get_templates
    render json: pdf_use_case_factory.get_templates.execute(
      user: user
    )
  end

  def create
    json = generate_and_store_use_case.execute(
      payment_ref: params_for_generate_and_store[:payment_ref],
      tenancy_ref: params_for_generate_and_store[:tenancy_ref],
      template_id: params_for_generate_and_store[:template_id],
      user: user
    )
    render json: json
  rescue Hackney::Income::TenancyNotFoundError
    head(404)
  end

  def send_letter
    document = find_document(params[:uuid])
    tenancy_ref = params[:tenancy_ref]

    send_letter_to_gov_notify.perform_later(document_id: document.id, tenancy_ref: tenancy_ref)
  end

  private

  def params_for_generate_and_store
    params.permit(
      :payment_ref,
      :template_id,
      :tenancy_ref,
      user: [:id, :name, :email, groups: []]
    )
  end

  def user
    user_params = params.require(:user).permit(:id, :name, :email, groups: [])

    Hackney::Domain::User.new.tap do |u|
      u.id = user_params['id']
      u.name = user_params['name']
      u.email = user_params['email']
      u.groups = user_params['groups']
    end
  end

  def find_document(uuid)
    Hackney::Cloud::Document.find_by!(uuid: uuid)
  end

  def send_letter_to_gov_notify
    Hackney::Income::Jobs::SendLetterToGovNotifyJob
  end

  def generate_and_store_use_case
    UseCases::GenerateAndStoreLetter.new
  end

  def income_collection_document?(document)
    metadata = JSON.parse(document.metadata)
    income_collection_templates = %w[income_collection_letter_1 income_collection_letter_2]
    metadata['template']['id'].in?(income_collection_templates)
  end
end
