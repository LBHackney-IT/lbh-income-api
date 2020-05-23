module Hackney
  module PDF
    class BankHolidays < ApplicationRecord
      def self.dates
        Rails.cache.fetch('Hackney/PDF/BankHolidays', expires_in: 1.day) do
          Hackney::PDF::BankHolidaysRetriever.new.execute
        end
      end
    end
  end
end
