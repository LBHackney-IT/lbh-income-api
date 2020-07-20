module CourtCaseResponseHelper
  def map_court_case_to_response(court_case:)
    {
      id: court_case.id,
      tenancyRef: court_case.tenancy_ref,
      courtDecisionDate: court_case.court_decision_date,
      courtOutcome: court_case.court_outcome,
      balanceAtOutcomeDate: court_case.balance_at_outcome_date,
      createdAt: court_case.created_at.strftime('%F')
    }
  end
end
