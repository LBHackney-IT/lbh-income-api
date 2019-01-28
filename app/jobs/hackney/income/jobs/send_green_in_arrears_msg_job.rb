module Hackney
  module Income
    module Jobs
      class SendGreenInArrearsMsgJob < ApplicationJob
        queue_as :message_jobs

        def perform(case_id:)
          case_priority = Hackney::Income::Models::CasePriority.find_by!(case_id: case_id)
          Rails.logger.info("Starting SendGreenInArrearsMsgJob for case id #{case_priority.case_id}")
          income_use_case_factory.send_automated_message_to_tenancy.execute(
            tenancy_ref: case_priority.tenancy_ref,
            sms_template_id: green_in_arrears_sms_template_id,
            email_template_id: green_in_arrears_email_template_id,
            batch_id: "SendGreenInArrearsMsgJob-#{case_priority.tenancy_ref}-#{SecureRandom.uuid}",
            variables: {
              balance: case_priority.balance
            }
          )
          Rails.logger.info("Finished SendGreenInArrearsMsgJob for case id #{case_priority.case_id}")
        end

        private

        def green_in_arrears_sms_template_id
          Rails.configuration.x.green_in_arrears.sms_template_id
        end

        def green_in_arrears_email_template_id
          Rails.configuration.x.green_in_arrears.email_template_id
        end
      end
    end
  end
end
