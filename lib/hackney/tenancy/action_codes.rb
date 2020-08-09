module Hackney
  module Tenancy
    module ActionCodes
      AUTOMATED_SMS_ACTION_CODE = 'GAT'.freeze
      AUTOMATED_EMAIL_ACTION_CODE = 'GAE'.freeze

      MANUAL_SMS_ACTION_CODE = 'GMS'.freeze
      MANUAL_EMAIL_ACTION_CODE = 'GME'.freeze

      MANUAL_GREEN_SMS_ACTION_CODE = 'GMS'.freeze
      MANUAL_AMBER_SMS_ACTION_CODE = 'AMS'.freeze

      LETTER_FAILED_VALIDATION_CODE = 'VFL'.freeze
      # Codes for letters as follows:
      LETTER_1_IN_ARREARS_FH = 'LF1'.freeze
      LETTER_2_IN_ARREARS_FH = 'LF2'.freeze
      LETTER_1_IN_ARREARS_LH = 'LL1'.freeze
      LETTER_2_IN_ARREARS_LH = 'LL2'.freeze
      LETTER_1_IN_ARREARS_SO = 'LS1'.freeze
      LETTER_2_IN_ARREARS_SO = 'LS2'.freeze

      INCOME_COLLECTION_LETTER_1 = 'IC1'.freeze
      INCOME_COLLECTION_LETTER_1_UH = 'S01'.freeze

      INCOME_COLLECTION_LETTER_2 = 'IC2'.freeze
      INCOME_COLLECTION_LETTER_2_UH = 'S02'.freeze
      INCOME_COLLECTION_LETTER_2_UH_ALT = 'ZR2'.freeze
      INCOME_COLLECTION_LETTER_2_UH_ALT_2 = 'ZL2'.freeze
      INCOME_COLLECTION_LETTER_2_UH_ALT_3 = 'ZT2'.freeze

      PRE_NOSP_WARNING_LETTER_SENT = 'IC3'.freeze
      COURT_WARNING_LETTER_SENT = 'IC4'.freeze

      COURT_BREACH_LETTER_SENT = 'CBL'.freeze
      INFORMAL_BREACH_LETTER_SENT = 'BLI'.freeze

      FIRST_FTA_LETTER_SENT = 'C'.freeze
      ARREARS_MAIL_MERGE_LETTER_SENT = 'MML'.freeze
      S0A_ALTERNATIVE_LETTER = 'S0A'.freeze
      FTA_REFUND_REQUEST_LETTER_SENT = 'REF'.freeze
      MW_LETTER_ACTION_1_COMPLETED = 'ZW1'.freeze
      MW_LETTER_ACTION_2_COMPLETED = 'ZW2'.freeze
      MW_LBA_LETTER_COMPLETED = 'ZW3'.freeze
      MW_LETTER_ACTION_1 = 'MW1'.freeze
      MW_LETTER_ACTION_2 = 'MW2'.freeze
      MW_LBA_LETTER = 'MW3'.freeze
      TEXT_MESSAGE_SENT = 'SMS'.freeze
      STAGE_ONE_COMPLETE = 'ZR1'.freeze
      STAGE_THREE_COMPLETE = 'ZR3'.freeze

      VISIT_MADE = 'VIM'.freeze

      WARRANT_OF_POSSESSION = 'WPA'.freeze

      PAUSED_MISSING_DATA = 'RMD'.freeze

      ADJOURNED_GENERALLY = Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY
      ADJOURNED_ON_TERMS = Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS
      CHARGE_AGAINST_PROPERTY = 'CAP'.freeze
      COSTS_AWARDED = 'CAW'.freeze
      COURT_BREACH_LETTER = 'CBL'.freeze
      COURT_OUTCOME_LETTER = 'IC5'.freeze
      COURT_WARNING_LETTER = 'IC4'.freeze
      COURT_DATE_SET = 'CDS'.freeze
      DWP_DIRECT_PAYMENTS_REQUESTED = 'DPQ'.freeze
      DECEASED = 'DEC'.freeze
      DELAYED_BENEFIT = 'MBH'.freeze
      DIRECT_DEBIT_CANCELLED = 'DDC'.freeze
      EVICTION = 'EVI'.freeze
      EVICTION_DATE_SET = 'EDS'.freeze
      FINANCIAL_INCLUSION_CALL = 'FIC'.freeze
      FINANCIAL_INCLUSION_INTERVIEW = 'FIO'.freeze
      FINANCIAL_INCLUSION_VISIT = 'FIV'.freeze
      HB_INVESTIGATION_PENDING = 'MHB'.freeze
      HB_OUTSTANDING = 'HBO'.freeze
      INCOMING_TELEPHONE_CALL = 'INC'.freeze
      MONEY_JUDGEMENT_AWARDED = 'MJA'.freeze
      NOTICE_SERVED = 'NTS'.freeze
      OFFICE_INTERVIEW = 'OFI'.freeze
      OUT_OF_HOURS_CALL = 'OOC'.freeze
      OUTGOING_TELEPHONE_CALL = 'OTC'.freeze
      POSTPONED_POSSESSION = Hackney::Tenancy::CourtOutcomeCodes::POSTPONED_POSSESSION
      PROMISE_OF_PAYMENT = 'POP'.freeze
      REFERRED_FOR_DEBT_ADVICE = 'DEB'.freeze
      SUSPENDED_POSSESSION = Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION
      UNIVERSAL_CREDIT = 'UCC'.freeze
      UNSUCCESSFUL_VISIT = 'VIU'.freeze

      CODES_THAT_PAUSES_CASES = [
        ADJOURNED_GENERALLY, ADJOURNED_ON_TERMS, CHARGE_AGAINST_PROPERTY, COSTS_AWARDED, COURT_BREACH_LETTER,
        COURT_OUTCOME_LETTER, COURT_WARNING_LETTER, COURT_DATE_SET, DWP_DIRECT_PAYMENTS_REQUESTED, DECEASED,
        DELAYED_BENEFIT, DIRECT_DEBIT_CANCELLED, EVICTION, EVICTION_DATE_SET, FINANCIAL_INCLUSION_CALL,
        FINANCIAL_INCLUSION_INTERVIEW, FINANCIAL_INCLUSION_VISIT, HB_INVESTIGATION_PENDING, HB_OUTSTANDING,
        INCOMING_TELEPHONE_CALL, MONEY_JUDGEMENT_AWARDED, NOTICE_SERVED, OFFICE_INTERVIEW, OUT_OF_HOURS_CALL,
        OUTGOING_TELEPHONE_CALL, POSTPONED_POSSESSION, PROMISE_OF_PAYMENT, REFERRED_FOR_DEBT_ADVICE,
        SUSPENDED_POSSESSION, UNIVERSAL_CREDIT, UNSUCCESSFUL_VISIT, WARRANT_OF_POSSESSION,
        COURT_BREACH_LETTER_SENT, VISIT_MADE, INCOME_COLLECTION_LETTER_1, INCOME_COLLECTION_LETTER_1_UH,
        INCOME_COLLECTION_LETTER_2, INCOME_COLLECTION_LETTER_2_UH, INCOME_COLLECTION_LETTER_2_UH_ALT,
        INCOME_COLLECTION_LETTER_2_UH_ALT_2, INCOME_COLLECTION_LETTER_2_UH_ALT_3, S0A_ALTERNATIVE_LETTER,
        COURT_WARNING_LETTER_SENT, WARRANT_OF_POSSESSION, AUTOMATED_SMS_ACTION_CODE, MANUAL_SMS_ACTION_CODE,
        MANUAL_GREEN_SMS_ACTION_CODE, MANUAL_AMBER_SMS_ACTION_CODE, TEXT_MESSAGE_SENT,
        INFORMAL_BREACH_LETTER_SENT
      ].freeze

      # Changing this list can have a big impact of the Classification system. If you add/remove you need to
      # ensure that the classifications are being calculated correctly. However, this is a bit tricky to do in
      # dev/test/staging. You will need to monitor any production deploys.
      FOR_UH_CRITERIA_SQL = [
        INCOME_COLLECTION_LETTER_1, INCOME_COLLECTION_LETTER_1_UH, INCOME_COLLECTION_LETTER_2,
        INCOME_COLLECTION_LETTER_2_UH_ALT, INCOME_COLLECTION_LETTER_2_UH_ALT_2,
        INCOME_COLLECTION_LETTER_2_UH_ALT_3, PRE_NOSP_WARNING_LETTER_SENT, COURT_WARNING_LETTER_SENT,
        LETTER_1_IN_ARREARS_FH, LETTER_2_IN_ARREARS_FH, LETTER_1_IN_ARREARS_LH,
        LETTER_2_IN_ARREARS_LH, LETTER_1_IN_ARREARS_SO, LETTER_2_IN_ARREARS_SO,
        AUTOMATED_SMS_ACTION_CODE, AUTOMATED_EMAIL_ACTION_CODE, MANUAL_SMS_ACTION_CODE,
        MANUAL_EMAIL_ACTION_CODE, MANUAL_AMBER_SMS_ACTION_CODE, FIRST_FTA_LETTER_SENT,
        ARREARS_MAIL_MERGE_LETTER_SENT, S0A_ALTERNATIVE_LETTER, FTA_REFUND_REQUEST_LETTER_SENT,
        MW_LETTER_ACTION_1_COMPLETED, MW_LETTER_ACTION_2_COMPLETED, MW_LBA_LETTER_COMPLETED,
        MW_LETTER_ACTION_1, MW_LETTER_ACTION_2, MW_LBA_LETTER, TEXT_MESSAGE_SENT,
        STAGE_ONE_COMPLETE, STAGE_THREE_COMPLETE, COURT_BREACH_LETTER_SENT, VISIT_MADE,
        INFORMAL_BREACH_LETTER_SENT
      ].freeze

      FOR_UH_LEASEHOLD_SQL = [
        LETTER_1_IN_ARREARS_LH, LETTER_2_IN_ARREARS_LH, LETTER_1_IN_ARREARS_FH, LETTER_2_IN_ARREARS_FH, LETTER_1_IN_ARREARS_SO, LETTER_2_IN_ARREARS_SO
      ].freeze
    end
  end
end
