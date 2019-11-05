module Hackney
  module Income
    class ProcessLetter
      def initialize(cloud_storage:)
        @cloud_storage = cloud_storage
      end

      def execute(uuid:, username:, email:)
        cached_letter_object = pop_from_cache(uuid)

        letter_html = cached_letter_object[:preview]

        @cloud_storage.save(
          letter_html: letter_html,
          filename: "#{uuid}.pdf",
          uuid: uuid,
          metadata: {
            username: username,
            email: email,
            payment_ref: cached_letter_object[:case][:payment_ref],
            template: cached_letter_object[:template]
          }
        )
      end

      private

      def pop_from_cache(uuid)
        result = Rails.cache.read(uuid)
        Rails.cache.delete(uuid)
        result
      end
    end
  end
end
