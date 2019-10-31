module Hackney
  module Income
    class SqlTenancyCaseGateway
      GatewayModel = Hackney::Income::Models::CasePriority

      # TODO: rename from tenancies
      def persist(tenancies:)
        tenancies.each do |tenancy|
          GatewayModel.find_or_create_by!(tenancy_ref: tenancy.tenancy_ref)
        end
      end

      def find(tenancy_ref:)
        tenancy = GatewayModel.find_by(tenancy_ref: tenancy_ref)
        Rails.logger.error("Failed to retrieve tenancy with tenancy_ref: '#{tenancy_ref}' ") if tenancy.nil?
        tenancy
      end
    end
  end
end
