require 'httparty'

module Hackney
  module Tenancy
    class ActionDiaryGateway
      def initialize(host:, key:)
        @action_diary_client = ActionDiary.new(host, key)
      end

      class ActionDiary
        include HTTParty
        base_uri @hostname

        def initialize(hostname, api_key)
          @hostname = hostname
          @options = {
            headers: { 'x-api-key': api_key }
          }
        end

        def create_entry(tenancy_ref:, action_code:, action_balance:, comment:, username: nil)
          url = File.join(@hostname + '/tenancies/arrears-action-diary')

          body = {
            tenancyAgreementRef: tenancy_ref,
            actionCode: action_code,
            actionBalance: action_balance,
            comment: comment
          }
          body[:username] = username unless username.nil?

          self.class.post(
            url,
            @options.merge(
              body: body.to_json
            )
          )
        end
      end

      def create_entry(tenancy_ref:, action_code:, action_balance:, comment:, username: nil)
        Rails.logger.info('Adding comment to action diary')
        @action_diary_client.create_entry(tenancy_ref: tenancy_ref, action_code: action_code, action_balance: action_balance, comment: comment, username: username)
      end
    end
  end
end
