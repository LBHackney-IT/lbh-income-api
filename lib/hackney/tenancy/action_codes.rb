module Hackney
  module Tenancy
    module ActionCodes
      AUTOMATED_SMS_ACTION_CODE = 'GAT'.freeze
      AUTOMATED_EMAIL_ACTION_CODE = 'GAE'.freeze

      MANUAL_SMS_ACTION_CODE = 'GMS'.freeze
      MANUAL_EMAIL_ACTION_CODE = 'GME'.freeze

      # FIXME:
      # Codes for letters as follows:
      # Letter 1 in arrears FH (code LF1)
      # Letter 2 in arrears FH (code LF2)
      # Letter 1 in arrears LH (code LL1)
      # Letter 2 in arrears LH (code LL2)
      # Letter 1 in arrears SO (code LS1)
      # Letter 2 in arrears SO (code LS2)

      LETTER_1_IN_ARREARS_FH = 'LF1'.freeze
    end
  end
end
