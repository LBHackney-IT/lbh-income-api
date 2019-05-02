require 'cgi'

namespace :bau do
  desc 'generate report of tenancy references that did not receive an SMS'
  task :failed_messages_report, [:tenancies_uri] do |_t, args|
    tenancies_uri = args.tenancies_uri || '/tenancies'
    tenancy_ref_regex = '\\d+/\\d+'
    uuid_regex = '[\\da-f\\-]{32,36}'
    matches = [
      # SendGreenInArrearsMsgJob-#{case_priority.tenancy_ref}-#{SecureRandom.uuid}
      Regexp.new("^\\S+-(#{tenancy_ref_regex})-#{uuid_regex}$"),
      # manual_#{tenancy.ref}
      Regexp.new("^\\S+_(#{tenancy_ref_regex})$")
    ]

    use_cases = Hackney::Income::UseCaseFactory.new
    use_cases.get_failed_sms_messages.execute.each do |message|
      reference = message[:reference]
      tenancy_refs = matches.map { |r| r.match(reference)&.values_at(1) }.flatten.compact
      tenancy_ref = tenancy_refs.first || reference

      puts "#{message[:phone_number]} -- #{tenancies_uri}/#{CGI.escape(tenancy_ref)}"
    end
  end
end
