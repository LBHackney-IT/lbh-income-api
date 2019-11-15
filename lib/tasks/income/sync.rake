namespace :income do
  namespace :sync do
    # manual_sync and enqueue_sync are identical except enqueue_sync passes the load off to active_job
    desc 'enqueues workers for income_use_case_factory.schedule_sync_cases.execute'
    task :enqueue do
      use_case_factory = Hackney::Income::UseCaseFactory.new
      use_case_factory.schedule_sync_cases.execute
    end

    desc 'manually runs the sync'
    task :manual_sync do
      use_case_factory = Hackney::Income::UseCaseFactory.new

      tenancy_refs = use_case_factory.uh_tenancies_gateway.tenancies_in_arrears

      tenancy_refs.each do |tenancy_ref|
        use_case_factory.sync_case_priority.execute(tenancy_ref: tenancy_ref)
      end
    end
  end
end
