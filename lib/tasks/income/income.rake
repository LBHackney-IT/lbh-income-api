namespace :income do
  namespace :tasks do
    desc 'Manual task, list all tenancies that match criteria for green in arrears messages'
    task :show_tenancies_green_in_arrears do |_task|
      use_case_factory = Hackney::Income::UseCaseFactory.new
      tenancy_refs = use_case_factory.show_green_in_arrears.execute.pluck(:tenancy_ref)
      puts '---'
      tenancy_refs.each do |ref|
        puts ref
      end
      puts '---'
    end
  end
end
