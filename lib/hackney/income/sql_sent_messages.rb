require 'active_record/errors'

module Hackney
  module Income
    class SqlSentMessages
      def add_message(tenancy_ref:, template_id:, version:, message_type:, personalisation:)
        sent_message = Hackney::Income::Models::SentMessage.create(
          tenancy_ref: tenancy_ref,
          template_id: template_id,
          version: version,
          message_type: message_type,
          personalisation: personalisation
        )
        sent_message.save
        sent_message
      end

      def get_sent_messages(tenancy_ref:, message_type:)
        Hackney::Income::Models::SentMessage.where(tenancy_ref: tenancy_ref).order(created_at: :desc)
      end
    end
  end
end
