class AgreementsController < ApplicationController
  def index
    requested_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: agreements_params.fetch(:tenancy_ref))

    agreements = requested_agreements.map do |agreement|
      {
        tenancyRef: agreement.tenancy_ref,
      }
    end

    render json: { agreements: agreements }
  end

  def agreements_params
    params.permit([:tenancy_ref]) 
  end
end
