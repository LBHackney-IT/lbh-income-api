module Hackney
  module Income
    class FetchActionsGateway
      GatewayModel = Hackney::IncomeCollection::Action

      def number_of_pages(number_per_page:, filters: {}, service_area_type:)
        (actions_filtered_for(service_area_type, filters).count.to_f / number_per_page).ceil
      end

      def get_actions(page_number: nil, number_per_page: nil, filters: {}, service_area_type:)
        query = actions_filtered_for(service_area_type, filters)

        query = query.offset((page_number - 1) * number_per_page).limit(number_per_page) if page_number.present? && number_per_page.present?

        order_options   = 'pause_until' if filters[:is_paused]
        order_options ||= by_balance

        query.order(order_options)
      end

      private

      def actions_filtered_for(service_area_type, filters)
        query = GatewayModel.where(service_area_type: service_area_type)
        if filters[:patch].present?
          if filters[:patch] == 'unassigned'
            query = query.where(patch_code: nil)
          else
            query = query.where(patch_code: filters[:patch])
          end
        end

        if filters[:classification].present?
          query = query.where(classification: filters[:classification])
        elsif only_show_immediate_actions?(filters)
          query = query.where.not(classification: :no_action).or(query.where(classification: nil))
        elsif filters[:pause_reason].present?
          query = query.where(pause_reason: filters[:pause_reason])
        end

        return query if filters[:is_paused].nil?

        if filters[:is_paused]
          query = query.where('pause_until > ?', Time.zone.now.beginning_of_day)
        else
          query = query.not_paused
        end
        query
      end

      def only_show_immediate_actions?(filters)
        filters_that_return_all_actions = [filters[:is_paused], filters[:full_patch]]
        filters_that_return_all_actions.all? { |filter| filter == false || filter.nil? }
      end

      def by_balance
        Arel.sql('balance DESC')
      end
    end
  end
end
