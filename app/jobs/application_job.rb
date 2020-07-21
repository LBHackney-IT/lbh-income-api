class ApplicationJob < ActiveJob::Base
  def income_use_case_factory
    @income_use_case_factory ||= Hackney::Income::UseCaseFactory.new
  end

  def leasehold_use_case_factory
    @leasehold_use_case_factory ||= Hackney::Leasehold::UseCaseFactory.new
  end

  def run_tenancy_sync_jobs?
    Rails.configuration.x.run_tenancy_sync_jobs
  end
end
