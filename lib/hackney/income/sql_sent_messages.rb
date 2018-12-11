require 'time'
require 'active_record/errors'

module Hackney
  module Income
    class SqlSentMessages
      def add_message (tenancy_ref:, template_id:, version:, message_type:, personalisation:)
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

      # def set_paused_until(tenancy_ref:, until_date:, pause_reason:, pause_comment:)
      #   tenancy = Hackney::Income::Models::Tenancy.find_by(tenancy_ref: tenancy_ref)
      #   raise "Unable to pause tenancy: #{tenancy_ref} - tenancy not found." if tenancy.nil?
      #   date = Time.iso8601(until_date)
      #   tenancy.update!(is_paused_until: date, pause_reason: pause_reason, pause_comment: pause_comment)
      # rescue ArgumentError
      #   raise "Unable to pause tenancy: #{tenancy_ref} until #{until_date} - invalid pause date."
      # rescue ActiveRecord::RecordNotSaved
      #   raise "Unable to pause tenancy: #{tenancy_ref} - something went wrong while updating."
      # end
      #
      # def get_tenancy_pause(tenancy_ref:)
      #   tenancy = Hackney::Income::Models::Tenancy.find_by(tenancy_ref: tenancy_ref)
      #   if tenancy.nil?
      #     Rails.logger.error("Failed to retrieve tenancy pause with tenancy_ref: '#{tenancy_ref}' ")
      #     raise PauseNotFoundError, "Unable to pause tenancy: #{tenancy_ref} - tenancy not found."
      #   end
      #   tenancy
      # end
      #
      # class PauseNotFoundError < StandardError; end
    end
  end
end
