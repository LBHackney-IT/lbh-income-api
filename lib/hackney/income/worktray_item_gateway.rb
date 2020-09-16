module Hackney
  module Income
    class WorktrayItemGateway
      GatewayModel = Hackney::IncomeCollection::Action
      SERVICE_AREA = 'rent'.freeze
      SECURE_TENURE_TYPE = 'SEC'.freeze

      CourtCaseModel = Hackney::Income::Models::CourtCase

      def store_worktray_item(tenancy_ref:, criteria:, classification:)
        gateway_model_instance = GatewayModel.find_or_initialize_by(tenancy_ref: tenancy_ref)
        court_case = CourtCaseModel.where(tenancy_ref: tenancy_ref).last

        begin
          gateway_model_instance.tap do |action|
            action.assign_attributes(
              balance: criteria.balance,
              classification: classification,
              payment_ref: criteria.payment_ref,
              patch_code: criteria.patch_code,
              action_type: SECURE_TENURE_TYPE,
              service_area_type: SERVICE_AREA,
              metadata: {
                collectable_arrears: criteria.collectable_arrears,
                weekly_rent: criteria.weekly_gross_rent,
                nosp_served: criteria.nosp_served?,
                nosp_served_date: criteria.nosp_served_date,
                active_nosp: criteria.active_nosp?,
                last_communication_action: criteria.last_communication_action,
                last_communication_date: criteria.last_communication_date,
                courtdate: court_case&.court_date,
                court_outcome: court_case&.court_outcome,
                eviction_date: criteria.eviction_date,
                universal_credit: criteria.universal_credit,
                uc_rent_verification: criteria. uc_rent_verification,
                uc_direct_payment_requested: criteria.uc_direct_payment_requested,
                uc_direct_payment_received: criteria.uc_direct_payment_received,
                days_since_last_payment: criteria.days_since_last_payment
              }
            )

            action.save! if action.changed?
          end
        rescue ActiveRecord::RecordNotUnique
          Rails.logger.error("A Tenancy with tenancy_ref: '#{tenancy_ref}' was inserted during find_or_create_by create operation, retrying...")
          retry
        end
      end

      def get_tenancies(page_number: nil, number_per_page: nil, filters: {})
        query = tenancies_filtered_for(filters)

        query = query.offset((page_number - 1) * number_per_page).limit(number_per_page) if page_number.present? && number_per_page.present?

        order_options   = "JSON_EXTRACT(metadata, '$.eviction_date')" if filters[:upcoming_evictions].present?
        order_options   = "JSON_EXTRACT(metadata, '$.courtdate')" if filters[:upcoming_court_dates].present?
        order_options   = 'pause_until' if filters[:is_paused]
        order_options ||= by_balance

        query.order(Arel.sql(order_options)).map(&method(:build_tenancy_list_item))
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
        # query.where("JSON_EXTRACT(metadata, '$.weekly_rent') = ?", 51.15)
        query = query.where("JSON_EXTRACT(metadata, '$.eviction_date') >= ?", Time.zone.now.beginning_of_day) if filters[:upcoming_evictions].present?
        # byebug
        query = query.where("JSON_EXTRACT(metadata, '$.courtdate') >= ?", Time.zone.now.beginning_of_day) if filters[:upcoming_court_dates].present?

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
          days_since_last_payment: model.metadata[:days_since_last_payment],
          nosp_served: model.metadata[:nosp_served],
          active_nosp: model.metadata[:active_nosp],
          patch_code: model.patch_code,
          classification: model.classification,
          courtdate: model.metadata[:courtdate],
          court_outcome: model.metadata[:court_outcome],
          eviction_date: model.metadata[:eviction_date],
          pause_reason: model.pause_reason,
          pause_comment: model.pause_comment,
          is_paused_until: model.pause_until
        }
      end
    end
  end
end
