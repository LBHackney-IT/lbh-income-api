module Hackney
  module Income
    class StoredActionsGateway
      GatewayModel = Hackney::IncomeCollection::Action

      def get_tenancies(page_number: nil, number_per_page: nil, filters: {})
        query = tenancies_filtered_for(filters)

        query = query.offset((page_number - 1) * number_per_page).limit(number_per_page) if page_number.present? && number_per_page.present?

        order_options   = 'eviction_date' if filters[:upcoming_evictions].present?
        order_options   = 'courtdate' if filters[:upcoming_court_dates].present?
        order_options   = 'is_paused_until' if filters[:is_paused]
        order_options ||= by_balance

        query.order(order_options).map(&method(:build_tenancy_list_item))
      end

      def number_of_pages(number_per_page:, filters: {})
        (tenancies_filtered_for(filters).count.to_f / number_per_page).ceil
      end

      private

      def tenancies_filtered_for(filters)
        query = GatewayModel.where('balance > ?', 0)

        if filters[:patch].present?
          if filters[:patch] == 'unassigned'
            query = query.where(patch_code: nil)
          else
            query = query.where(patch_code: filters[:patch])
          end
        end

        query = query.where('eviction_date >= ?', Time.zone.now.beginning_of_day) if filters[:upcoming_evictions].present?
        query = query.where('courtdate >= ?', Time.zone.now.beginning_of_day) if filters[:upcoming_court_dates].present?

        if filters[:classification].present?
          query = query.where(classification: filters[:classification])
        elsif only_show_immediate_actions?(filters)
          query = query.where.not(classification: :no_action).or(query.where(classification: nil))
        elsif filters[:pause_reason].present?
          query = query.where(pause_reason: filters[:pause_reason])
        end

        return query if filters[:is_paused].nil?

        if filters[:is_paused]
          query = query.where('is_paused_until > ?', Time.zone.now.beginning_of_day)
        else
          query = query.not_paused
        end
        query
      end

      def only_show_immediate_actions?(filters)
        filters_that_return_all_actions = [filters[:is_paused], filters[:full_patch], filters[:upcoming_evictions], filters[:upcoming_court_dates]]
        filters_that_return_all_actions.all? { |filter| filter == false || filter.nil? }
      end

      def by_balance
        Arel.sql('balance DESC')
      end

      def build_tenancy_list_item(model)
        {
          tenancy_ref: model.tenancy_ref,
          balance: model.balance,
          days_in_arrears: model.days_in_arrears,
          days_since_last_payment: model.days_since_last_payment,
          number_of_broken_agreements: model.number_of_broken_agreements,
          active_agreement: model.active_agreement,
          broken_court_order: model.broken_court_order,
          nosp_served: model.nosp_served,
          active_nosp: model.active_nosp,
          patch_code: model.patch_code,
          classification: model.classification,
          courtdate: model.courtdate,
          court_outcome: model.court_outcome,
          eviction_date: model.eviction_date,
          latest_active_agreement_date: model.latest_active_agreement_date,
          breach_agreement_date: model.breach_agreement_date,
          expected_balance: model.expected_balance,
          pause_reason: model.pause_reason,
          pause_comment: model.pause_comment,
          is_paused_until: model.is_paused_until
        }
      end
    end
  end
end
