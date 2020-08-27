module Hackney
  module LetterDateHelper
    def format_date(date)
      return if date.nil?

      date.strftime('%d %B %Y')
    end
  end
end
