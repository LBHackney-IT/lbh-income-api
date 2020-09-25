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
  describe Hackney::Income::TenancyClassification::Classifier do
    it_behaves_like 'TenancyClassification examples', condition_matrix
  end
end

shared_examples 'TenancyClassification examples' do |condition_matrix|
  subject { assign_classification.execute }

  let(:assign_classification) {
    described_class.new(
      case_priority, criteria, []
    )
  }

  let(:criteria) { Stubs::StubCriteria.new(attributes) }
  let(:case_priority) { build_stubbed(:case_priority, is_paused_until: is_paused_until) }
  let(:agreement_model) { Hackney::Income::Models::Agreement }
  let(:court_case_model) { Hackney::Income::Models::CourtCase }
  let(:eviction_model) { Hackney::Income::Models::Eviction }

  let(:attributes) do
    {
      balance: balance,
      collectable_arrears: collectable_arrears,
      weekly_rent: weekly_rent,
      last_communication_date: last_communication_date,
      last_communication_action: last_communication_action,
      nosp_served_date: nosp_served_date,
      eviction_date: eviction_date,
      expected_balance: expected_balance,
      days_since_last_payment: days_since_last_payment,
      total_payment_amount_in_week: total_payment_amount_in_week
    }
  end

  condition_matrix.each do |options|
    context(options[:description] || build_context_message(options)) do
      let(:is_paused_until) { options[:is_paused_until] }
      let(:balance) { options[:balance] }
      let(:collectable_arrears) { options[:collectable_arrears] }
      let(:weekly_rent) { options[:weekly_rent] }
      let(:last_communication_date) { options[:last_communication_date] }
      let(:last_communication_action) { options[:last_communication_action] }
      let(:nosp_served_date) { options[:nosp_served_date] }
      let(:eviction_date) { options[:eviction_date] || '' }
      let(:expected_balance) { options[:expected_balance] }
      let(:days_since_last_payment) { options[:days_since_last_payment] }
      let(:total_payment_amount_in_week) { options[:total_payment_amount_in_week] }
      let(:active_agreement) { options[:active_agreement] }
      let(:most_recent_agreement) { options[:most_recent_agreement] }
      let(:court_outcome) { options[:court_outcome] }
      let(:courtdate) { options[:courtdate] }

      before do
        if courtdate.present? || court_outcome.present?
          if court_outcome.present? && court_outcome == Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE
            # We should update these on the examples once UH examples are decommissioned so we won't need this mapping
            disrepair_counter_claim = true
            terms = true
            outcome = Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE
          end
          court_case = build_stubbed(:court_case, tenancy_ref: criteria.tenancy_ref,
                                                  court_date: courtdate,
                                                  court_outcome: outcome || court_outcome,
                                                  disrepair_counter_claim: disrepair_counter_claim,
                                                  terms: terms)
        end

        eviction = build_stubbed(:eviction, tenancy_ref: criteria.tenancy_ref, date: eviction_date) if eviction_date.present?

        if most_recent_agreement.present?
          agreement_type = court_case.present? && court_case.result_in_agreement? ? :formal : :informal
          state = most_recent_agreement[:breached] == true ? :breached : :live
          agreement = build_stubbed(:agreement,
                                    agreement_type: agreement_type,
                                    tenancy_ref: criteria.tenancy_ref,
                                    start_date: most_recent_agreement[:start_date],
                                    court_case_id: court_case&.id,
                                    current_state: state)
        elsif active_agreement == true
          agreement = build_stubbed(:agreement, tenancy_ref: criteria.tenancy_ref, current_state: :live)
        end

        allow(court_case_model).to receive(:where).with(tenancy_ref: criteria.tenancy_ref).and_return([court_case])
        allow(agreement_model).to receive(:where).with(tenancy_ref: criteria.tenancy_ref).and_return([agreement])
        allow(eviction_model).to receive(:where).with(tenancy_ref: criteria.tenancy_ref).and_return([eviction])
      end

      if options[:outcome]
        it "returns `#{options[:outcome]}`" do
          expect(subject).to eq(options[:outcome])
        end
      elsif options[:outcome_not]
        it "does not return `#{options[:outcome_not]}`" do
          expect(subject).not_to eq(options[:outcome_not])
        end
      else
        raise 'outcome or outcome_not as an option'
      end
    end
  end
end
