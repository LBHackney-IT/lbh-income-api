module Hackney
  module Domain
    class User
      attr_accessor :id, :name, :email, :groups

      def leasehold_services?
        groups.join(' ').include?('leasehold')
      end

      def income_collection?
        groups.join(' ').include?('income')
      end
    end
  end
end
