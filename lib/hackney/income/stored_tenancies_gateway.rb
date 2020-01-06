module Hackney
  module Income
    class StoredTenanciesGateway
      GatewayModel = Hackney::Income::Models::CasePriority

      def store_tenancy(tenancy_ref:, criteria:)
        gateway_model_instance = GatewayModel.find_or_initialize_by(tenancy_ref: tenancy_ref)
        classification_usecase = Hackney::Income::TenancyPrioritiser::TenancyClassification.new(
          gateway_model_instance,
          criteria
        )

        begin
          gateway_model_instance.tap do |tenancy|
            tenancy.update(
              balance: criteria.balance,
              weekly_rent: criteria.weekly_rent,
              days_in_arrears: criteria.days_in_arrears,
              days_since_last_payment: criteria.days_since_last_payment,
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
              patch_code: criteria.patch_code,
              courtdate: criteria.courtdate,
              court_outcome: criteria.court_outcome,
              eviction_date: criteria.eviction_date,
              universal_credit: criteria.universal_credit,
              uc_rent_verification: criteria. uc_rent_verification,
              uc_direct_payment_requested: criteria.uc_direct_payment_requested,
              uc_direct_payment_received: criteria.uc_direct_payment_received,
              latest_active_agreement_date: criteria.latest_active_agreement_date,
              breach_agreement_date: criteria.breach_agreement_date,
              expected_balance: criteria.expected_balance
            )
          end
        rescue ActiveRecord::RecordNotUnique
          Rails.logger.error("A Tenancy with tenancy_ref: '#{tenancy_ref}' was inserted during find_or_create_by create operation, retrying...")
          retry
        end
      end

      def get_tenancies(page_number: nil, number_per_page: nil, filters: {})
        query = tenancies_filtered_for(filters)

        query = query.offset((page_number - 1) * number_per_page).limit(number_per_page) if page_number.present? && number_per_page.present?

        order_options   = 'eviction_date' if filters[:upcoming_evictions].present?
        order_options   = 'courtdate' if filters[:upcoming_court_dates].present?
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
        end

        return query if filters[:is_paused].nil?

        if filters[:is_paused]
          query = query.where('is_paused_until >= ?', Date.today)
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
          expected_balance: model.expected_balance
        }
      end
    end
  end
end
