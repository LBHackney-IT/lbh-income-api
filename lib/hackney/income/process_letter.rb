module Hackney
  module Income
    class ProcessLetter
      def initialize(cloud_storage:)
        @cloud_storage = cloud_storage
      end

      def execute(uuid:, username:, email:, payment_ref:, template_name:, letter_content:)
        @cloud_storage.save(
          letter_html: letter_content,
          filename: "#{uuid}.pdf",
          uuid: uuid,
          metadata: {
            payment_ref: payment_ref,
            template: template_name,
            username: username,
            email: email
          }
        )
      end
    end
  end
end
