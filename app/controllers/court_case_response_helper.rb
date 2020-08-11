module CourtCaseResponseHelper
  def map_court_case_to_response(court_case:)
    {
      id: court_case.id,
      tenancyRef: court_case.tenancy_ref,
      courtDate: court_case.court_date,
      courtOutcome: court_case.court_outcome,
      balanceOnCourtOutcomeDate: court_case.balance_on_court_outcome_date,
      strikeOutDate: court_case.strike_out_date,
      terms: court_case.terms,
      disrepairCounterClaim: court_case.disrepair_counter_claim
    }
  end
end
