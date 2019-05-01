require 'json'

namespace :bau do

  desc 'generate case totals for each user'
  task :case_totals, [:tenancy_ref, :user_id] do
    user_cases = []
    users = Hackney::Income::Models::User.all
    users.each do |user|
      cases = Hackney::Income::Models::CasePriority.where(assigned_user_id: user[:user_id])
      green = cases.where(priority_band: :green)
      amber = cases.where(priority_band: :amber)
      red = cases.where(priority_band: :red)
      user_cases << {
        name: user.name,
        total: cases.length,
        green: green.length,
        amber: amber.length,
        red: red.length
      }
    end
    puts JSON.pretty_generate(user_cases)
  end
end
