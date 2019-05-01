namespace :bau do
  desc 'reassign case to user'
  task :reassign_case, [:tenancy_ref, :user_id] do
    user_assignment_gateway = Hackney::Income::SqlTenancyCaseGateway.new
    user_assignment_gateway.assign_user(tenancy_ref: tenancy_ref, user_id: user_id)
  end
end
