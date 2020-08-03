module CourtCaseResponseHelper
  def map_court_case_to_response(court_case:)
    {
      id: court_case.id,
      tenancyRef: court_case.tenancy_ref,
      dateOfCourtDecision: court_case.date_of_court_decision,
      courtOutcome: court_case.court_outcome,
      balanceOnCourtOutcomeDate: court_case.balance_on_court_outcome_date,
      createdAt: court_case.created_at.strftime('%F'),
      strikeOutDate: court_case.strike_out_date.strftime('%F'),
      createdBy: court_case.created_by
    }
  end
end
