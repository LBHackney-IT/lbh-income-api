module Hackney
  module PDF
    class BankHolidays
      def self.dates(bank_holidays_retriever)
        Rails.cache.fetch('Hackney/PDF/BankHolidays', expires_in: 1.day) do
          bank_holidays_retriever.execute
        end
      end
    end
  end
end
