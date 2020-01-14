#
# Build up a message to put into the testing context. The message will include all the data that can
# effect the classification outcome. It will produce a context message that looks like the following:
#   "when 'nosps_in_last_year' is '0', 'nosp_expiry_date' is '', 'weekly_rent' is '5',
#   'balance' is '25.0', 'is_paused_until' is '', 'active_agreement' is 'false',
#   'last_communication_date' is '2019-11-19', 'last_communication_action' is 'IC3',
#   'eviction_date' is '', 'courtdate' is '2019-09-27 16:39:53 UTC'"
# The `outcome` is skipped as we use it in the `it` message instead. That will look like the following:
#  "returns `send_NOSP`"
#
def build_context_message(options)
  'when ' + options.each_with_object([]) do |(attribute, value), msg|
    next msg if attribute == :outcome
    msg << "'#{attribute}' is '#{value}'"
    msg
  end.join(', ')
end

#
# `condition_matrix` is an Array of Hashes containing the mandatory key of `outcome` this is what
# the classification system should evaluate the other attributes as. For a list of data you can set
# see the `let`s in the `context` towards the end of this file.
#
# Alternatively, see any file that uses the Shared Example and see what they are supplying.
#
shared_examples 'TenancyClassification' do |condition_matrix|
  subject { assign_classification.execute }

  let(:assign_classification) {
    Hackney::Income::TenancyPrioritiser::TenancyClassification.new(
      case_priority, criteria, []
    )
  }
  let(:criteria) { Stubs::StubCriteria.new(attributes) }
  let(:case_priority) { build(:case_priority, is_paused_until: is_paused_until) }

  let(:attributes) do
    {
      balance: balance,
      weekly_rent: weekly_rent,
      last_communication_date: last_communication_date,
      last_communication_action: last_communication_action,
      active_agreement: active_agreement,
      nosps_in_last_year: nosps_in_last_year,
      nosp_served_date: nosp_served_date,
      nosp_expiry_date: nosp_expiry_date,
      courtdate: courtdate,
      eviction_date: eviction_date,
      court_outcome: court_outcome,
      latest_active_agreement_date: latest_active_agreement_date,
      breach_agreement_date: breach_agreement_date,
      number_of_broken_agreements: number_of_broken_agreements,
      expected_balance: expected_balance,
      most_recent_agreement: most_recent_agreement
    }
  end

  condition_matrix.each do |options|
    context(options[:description] || build_context_message(options)) do
      let(:is_paused_until) { options[:is_paused_until] }
      let(:balance) { options[:balance] }
      let(:weekly_rent) { options[:weekly_rent] }
      let(:last_communication_date) { options[:last_communication_date] }
      let(:last_communication_action) { options[:last_communication_action] }
      let(:active_agreement) { options[:active_agreement] }
      let(:nosps_in_last_year) { options[:nosps_in_last_year] }
      let(:nosp_served_date) { options[:nosp_served_date] }
      let(:nosp_expiry_date) { options[:nosp_expiry_date] }
      let(:court_outcome) { options[:court_outcome] }
      let(:courtdate) { options[:courtdate] }
      let(:eviction_date) { options[:eviction_date] || '' }
      let(:latest_active_agreement_date) { options[:latest_active_agreement_date] }
      let(:breach_agreement_date) { options[:breach_agreement_date] }
      let(:number_of_broken_agreements) { options[:number_of_broken_agreements] }
      let(:expected_balance) { options[:expected_balance] }
      let(:most_recent_agreement) { options[:most_recent_agreement] }

      it "returns `#{options[:outcome]}`" do
        expect(subject).to eq(options[:outcome])
      end
    end
  end
end
