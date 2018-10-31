namespace :income do
  task :sync do
    use_case_factory = Hackney::Income::UseCaseFactory.new
    use_case_factory.sync_cases.execute
  end

  desc 'Manual task, supply a 3 character patch code and the user ID for a user in our SQL database. All tenancies in that patch where the high action is 4RS or above will be assigned to that user.'
  task :migrate_lcw_cases, [:patch, :user_id] do |_task, args|
    use_case_factory = Hackney::Income::UseCaseFactory.new
    use_case_factory.migrate_patch_to_lcw.execute(patch: args.fetch(:patch), user_id: args.fetch(:user_id))
  end
end
