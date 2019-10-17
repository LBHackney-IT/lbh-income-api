module Hackney
  module Income
    class StoredTenanciesGateway
      GatewayModel = Hackney::Income::Models::CasePriority

      def store_tenancy(tenancy_ref:, priority_band:, priority_score:, criteria:, weightings:)
        score_calculator = Hackney::Income::TenancyPrioritiser::Score.new(
          criteria,
          weightings
        )
        classification_usecase = Hackney::Income::TenancyPrioritiser::TenancyClassification.new(criteria)

        begin
          GatewayModel.find_or_create_by(tenancy_ref: tenancy_ref).tap do |tenancy|
            tenancy.update(
              priority_band: priority_band,
              priority_score: priority_score,

              balance_contribution: score_calculator.balance,
              days_in_arrears_contribution: score_calculator.days_in_arrears,
              days_since_last_payment_contribution: score_calculator.days_since_last_payment,
              payment_amount_delta_contribution: score_calculator.payment_amount_delta,
              payment_date_delta_contribution: score_calculator.payment_date_delta,
              number_of_broken_agreements_contribution: score_calculator.number_of_broken_agreements,
              active_agreement_contribution: score_calculator.active_agreement,
              broken_court_order_contribution: score_calculator.broken_court_order,
              nosp_served_contribution: score_calculator.nosp_served,
              active_nosp_contribution: score_calculator.active_nosp,

              balance: criteria.balance,
              weekly_rent: criteria.weekly_rent,
              days_in_arrears: criteria.days_in_arrears,
              days_since_last_payment: criteria.days_since_last_payment,
              payment_amount_delta: criteria.payment_amount_delta,
              payment_date_delta: criteria.payment_date_delta,
              number_of_broken_agreements: criteria.number_of_broken_agreements,
              active_agreement: criteria.active_agreement?,
              broken_court_order: criteria.broken_court_order?,
              nosp_served: criteria.nosp_served?,
              nosp_served_date: criteria.nosp_served_date,
              nosp_expiry_date: criteria.nosp_expiry_date,
              last_communication_action: criteria.last_communication_action,
              last_communication_date: criteria.last_communication_date,
              active_nosp: criteria.active_nosp?,
              classification: classification_usecase.execute,
              patch_code: criteria.patch_code
            )
          end
        rescue ActiveRecord::RecordNotUnique
          Rails.logger.error("A Tenancy with tenancy_ref: '#{tenancy_ref}' was inserted during find_or_create_by create operation, retrying...")
          retry
        end
      end

      def get_tenancies_for_user(user_id:, page_number: nil, number_per_page: nil, filters: {})
        query = tenancies_filtered_for(user_id, filters)

        query = query.offset((page_number - 1) * number_per_page).limit(number_per_page) if page_number.present? && number_per_page.present?

        query.order(by_balance).map(&method(:build_tenancy_list_item))
      end

      def number_of_pages_for_user(user_id:, number_per_page:, filters: {})
        (tenancies_filtered_for(user_id, filters).count.to_f / number_per_page).ceil
      end

      private

      # filters: {
      #   is_paused: nil,
      #   classification: nil,
      #   patch: nil
      # }
      def tenancies_filtered_for(user_id, filters)
        query = GatewayModel.where('
          assigned_user_id = ? AND
          balance > ?', user_id, 0)

        query = query.where('patch_code = ?', filters[:patch]) if filters[:patch]
        query = query.where(classification: filters[:classification]) if filters[:classification]

        return query if filters[:is_paused].nil?

        if filters[:is_paused]
          query = query.where('is_paused_until >= ?', Date.today)
        else
          query = query.not_paused
        end
        query
      end

      def by_balance
        Arel.sql('balance DESC')
      end

      def build_tenancy_list_item(model)
        {
          tenancy_ref: model.tenancy_ref,
          priority_band: model.priority_band,
          priority_score: model.priority_score,

          balance_contribution: model.balance_contribution,
          days_in_arrears_contribution: model.days_in_arrears_contribution,
          days_since_last_payment_contribution: model.days_since_last_payment_contribution,
          payment_amount_delta_contribution: model.payment_amount_delta_contribution,
          payment_date_delta_contribution: model.payment_date_delta_contribution,
          number_of_broken_agreements_contribution: model.number_of_broken_agreements_contribution,
          active_agreement_contribution: model.active_agreement_contribution,
          broken_court_order_contribution: model.broken_court_order_contribution,
          nosp_served_contribution: model.nosp_served_contribution,
          active_nosp_contribution: model.active_nosp_contribution,

          balance: model.balance,
          days_in_arrears: model.days_in_arrears,
          days_since_last_payment: model.days_since_last_payment,
          payment_amount_delta: model.payment_amount_delta,
          payment_date_delta: model.payment_date_delta,
          number_of_broken_agreements: model.number_of_broken_agreements,
          active_agreement: model.active_agreement,
          broken_court_order: model.broken_court_order,
          nosp_served: model.nosp_served,
          active_nosp: model.active_nosp,
          patch_code: model.patch_code,

          classification: model.classification
        }
      end
    end
  end
end
