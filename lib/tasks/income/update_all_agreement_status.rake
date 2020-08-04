namespace :income do
  desc 'manually runs update all agreement state job'
  task :update_all_agreement_state do
    p 'checking and updating agreement states'
    use_case_factory = Hackney::Income::UseCaseFactory.new
    use_case_factory.update_all_agreement_states.execute
  end
end
