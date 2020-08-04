require 'sidekiq-scheduler'

class UpdateAllAgreementState
  include Sidekiq::Worker

  def perform
    puts '* Scheduling UpdateAllAgreementState *'

    use_case_factory = Hackney::Income::UseCaseFactory.new
    use_case_factory.update_all_agreement_states.execute
  end
end
