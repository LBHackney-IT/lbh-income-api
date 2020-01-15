module Hackney
  module Notification
    class BaseManualGateway
      attr_writer :notification_gateway, :add_action_diary_and_sync_case_usecase, :document_store, :leasehold_gateway, :case_priority_store

      def initialize(notification_gateway:, add_action_diary_and_sync_case_usecase:, leasehold_gateway: nil, document_store: nil, case_priority_store: nil)
        self.notification_gateway = notification_gateway
        self.add_action_diary_and_sync_case_usecase = add_action_diary_and_sync_case_usecase
        self.document_store = document_store
        self.leasehold_gateway = leasehold_gateway
        self.case_priority_store = case_priority_store
      end

      def execute
        raise "#{self.class} execute not implemented"
      end

      private

      attr_reader :notification_gateway, :add_action_diary_and_sync_case_usecase, :document_store, :leasehold_gateway, :case_priority_store
    end
  end
end
