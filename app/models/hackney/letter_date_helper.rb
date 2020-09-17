module Hackney
  module LetterDateHelper
    def format_date(date)
      return if date.nil?

      date.strftime('%d %B %Y')
    end

    def format_time(time)
      return if time.nil?

      time.strftime('%R')
    end
  end
end
