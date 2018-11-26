require 'httparty'
require_relative 'exceptions/tenancy_api_exception.rb'

module Hackney
  module Tenancy
    class ActionDiaryGateway
      include HTTParty
      format :json

      def initialize(host:, api_key:)
        self.class.base_uri host
        @options = {
          headers: { 'x-api-key': api_key }
        }
      end

      def create_entry(tenancy_ref:, action_code:, action_balance:, comment:, username: nil)
        body = {
          tenancyAgreementRef: tenancy_ref,
          actionCode: action_code,
          actionBalance: action_balance,
          comment: comment
        }
        body[:username] = username unless username.nil?

        request = self.class.post('/tenancies/arrears-action-diary', @options.merge(body: body.to_json))
        raise TenancyApiException unless request.success?
        request
      end
    end
  end
end
