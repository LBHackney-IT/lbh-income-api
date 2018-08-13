class MyCasesController < ApplicationController
  def index
    cases = view_my_cases.execute(random_tenancy_refs)
    render json: cases
  end

  private

  def view_my_cases
    Hackney::Income::DangerousViewMyCases.new(
      tenancy_api_gateway: Hackney::Income::TenancyApiGateway.new(host: 'http://tenancy_api'),
      stored_tenancies_gateway: Hackney::Income::StoredTenanciesGateway.new
    )
  end

  def random_tenancy_refs
    Hackney::Income::Models::Tenancy.first(100).map { |t| t.tenancy_ref }
  end
end
