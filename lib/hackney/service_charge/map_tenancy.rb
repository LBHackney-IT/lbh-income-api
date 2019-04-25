module Hackney
  module ServiceCharge
    class MapTenancy
      def initialize(service_charge_gateway:)
        @service_charge_gateway = service_charge_gateway
      end

      def execute(payment_ref:)
        @service_charge_gateway.map_tenancy_ref_to_payment_ref(payment_ref)
      end
    end
  end
end
