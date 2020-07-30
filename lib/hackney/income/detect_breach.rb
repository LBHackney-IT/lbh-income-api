module Hackney
  module Income
    class DetectBreach
      def initialize(tolerance_days:)
        @tolerance_days = tolerance_days
      end

      def execute(agreement:)
        return false unless agreement.active?
        return false unless breached?(agreement)

        Hackney::Income::Models::AgreementState.create!(agreement_id: agreement.id, agreement_state: :breached)
      end

      private

      def breached?(agreement)
        date_of_first_check = agreement.start_date + @tolerance_days.days

        return false if date_of_first_check.future?

        number_of_instalments = number_of_instalments(date_of_first_check, agreement.frequency)
        expected_balance = agreement.starting_balance - (number_of_instalments * agreement.amount)
        current_balance = Hackney::Income::Models::CasePriority.where(tenancy_ref: agreement.tenancy_ref).first.balance.to_f

        expected_balance < current_balance
      end

      def number_of_instalments(date, frequency)
        instalments = if frequency == 'weekly'
                        payment_cycles_since(date, 7)
                      elsif frequency == 'fortnightly'
                        payment_cycles_since(date, 14)
                      elsif frequency == '4 weekly'
                        payment_cycles_since(date, 28)
                      else
                        full_months_since(date)
                      end
        instalments + 1
      end

      def full_months_since(date, number = 0)
        date += 1.month
        return number if date > Time.now.beginning_of_day
        return number + 1 if date == Time.now.beginning_of_day

        full_months_since(date, number + 1)
      end

      def payment_cycles_since(date, days)
        time_difference = Time.now.beginning_of_day - date
        number_cycles = (time_difference / days.days).to_i

        prevent_negative(number_cycles)
      end

      def prevent_negative(number)
        [number, 0].max
      end
    end
  end
end
