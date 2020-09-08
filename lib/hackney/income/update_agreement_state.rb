module Hackney
  module Income
    class UpdateAgreementState
      def initialize(tolerance_days:)
        @tolerance_days = tolerance_days
      end

      def execute(agreement:, current_balance:)
        return false unless agreement.active?
        return false if agreement.frequency == 'unsupported_legacy_frequency'

        update_status(agreement, current_balance)
      end

      private

      def update_status(agreement, current_balance)
        if agreement.formal?
          strike_out(agreement)

          return add_new_state(agreement, :completed, nil, nil) if end_of_lifecycle?(agreement)
        end

        expected_balance = expected_balance(agreement)

        return update_last_checked_date(agreement) if state_has_not_changed?(agreement, expected_balance, current_balance)

        new_state = if current_balance <= 0 && strike_out_date_blank?(agreement)
                      :completed
                    elsif expected_balance < current_balance
                      :breached
                    else
                      :live
                    end

        add_new_state(agreement, new_state, expected_balance, current_balance)
      end

      def expected_balance(agreement)
        initial_payment_amount = initial_payment_amount(agreement)
        first_recurring_payment_date = first_recurring_payment_date(agreement)

        return prevent_negative(agreement.starting_balance - initial_payment_amount) if first_recurring_payment_date.future?

        number_of_instalments = number_of_instalments(first_recurring_payment_date, agreement.frequency)
        expected_balance = agreement.starting_balance - initial_payment_amount - (number_of_instalments * agreement.amount)

        prevent_negative(expected_balance)
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

      def first_recurring_payment_date(agreement)
        agreement.start_date + @tolerance_days.days
      end

      def update_last_checked_date(agreement)
        Hackney::Income::Models::AgreementState.where(agreement_id: agreement.id).last&.touch
      end

      def add_new_state(agreement, new_state, expected_balance, current_balance)
        description = if new_state == :breached
                        "Breached by £#{current_balance - expected_balance}"
                      elsif new_state == :completed
                        Date.today.strftime('Completed on %m/%d/%Y')
                      else
                        'Checked by the system'
                      end

        Hackney::Income::Models::AgreementState.create!(
          agreement: agreement,
          agreement_state: new_state,
          expected_balance: expected_balance,
          checked_balance: current_balance,
          description: description
        )
      end

      def state_has_not_changed?(agreement, expected_balance, current_balance)
        current_state = agreement.agreement_states.last
        current_state.expected_balance == expected_balance && current_state.checked_balance == current_balance
      end

      def strike_out(agreement)
        return unless agreement.court_case.strike_out_date.present?
        return unless agreement.court_case.strike_out_date <= Date.today

        agreement.update!(agreement_type: :informal)
      end

      def end_of_lifecycle?(agreement)
        return false unless agreement.court_case.court_outcome == Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS

        return false unless court_date_older_than_6_years(agreement.court_case.court_date)
        true
      end

      def court_date_older_than_6_years(court_date)
        return false if court_date.nil?
        court_date + 6.years <= Date.today
      end

      def strike_out_date_blank?(agreement)
        return true if agreement.informal?
        agreement.court_case.strike_out_date.blank?
      end

      def initial_payment_date(agreement)
        return nil unless agreement.variable_payment?

        agreement.initial_payment_date + @tolerance_days.days
      end

      def initial_payment_amount(agreement)
        return 0 unless agreement.variable_payment?
        return 0 if initial_payment_date(agreement).future?

        agreement.initial_payment_amount
      end
    end
  end
end
