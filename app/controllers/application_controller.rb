class ApplicationController < ActionController::API
  before_action :set_raven_context

  def letter_use_case_factory
    @letter_use_case_factory = Hackney::Letter::UseCaseFactory.new
  end

  def income_use_case_factory
    @income_use_case_factory ||= Hackney::Income::UseCaseFactory.new
  end

  def pdf_use_case_factory
    @pdf_use_case_factory ||= Hackney::PDF::UseCaseFactory.new
  end

  def service_charge_use_case_factory
    @service_charge_use_case_factory ||= Hackney::Leasehold::UseCaseFactory.new
  end

  def set_raven_context
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
