module Hackney
  module Income
    class GetSentMessages
      def initialize(sql_gateway:, notifications_gateway:)
        @sql_gateway = sql_gateway
        @notifications_gateway = notifications_gateway
      end

      def execute(tenancy_ref:, type:)
        sent_templates = @sql_gateway.get_sent_messages(
          tenancy_ref: tenancy_ref,
          message_type: type
        )
        sent_messages = []
        unless sent_templates.empty?
          sent_templates.each do |tmp|
            template = @notifications_gateway.get_sent_template(
              template_id: tmp.template_id,
              version: tmp.version
            )
            sent_messages << personalise_template(template, JSON.parse(tmp.personalisation))
          end
        end
        sent_messages
      end

      private

      def personalise_template(template, personalisation)
        personalisation.each do |key, value|
          template.body["((#{key}))"] = value if template.body["((#{key}))"]
          template.subject["((#{key}))"] = value if template.subject["((#{key}))"]
        end

        template
      end
    end
  end
end
