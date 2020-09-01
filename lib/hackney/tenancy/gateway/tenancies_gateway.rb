require 'uri'
require 'net/http'
require "#{Rails.root}/lib/hackney/tenancy/exceptions/tenancy_api_exception"

module Hackney
  module Tenancy
    module Gateway
      class TenanciesGateway
        def initialize(host:, key:)
          @host = host
          @key = key
        end

        def get_tenancies_by_refs(refs)
          return [] if refs.empty?

          uri = URI("#{@host}/api/v1/tenancies?#{params_list('tenancy_refs', refs)}")

          req = Net::HTTP::Get.new(uri)
          req['X-Api-Key'] = @key

          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) { |http| http.request(req) }

          raise Hackney::Tenancy::Exceptions::TenancyApiException, res unless res.is_a? Net::HTTPSuccess

          body = JSON.parse(res.body)

          body['tenancies'].map do |tenancy|
            {
              ref: tenancy.fetch('ref'),
              current_balance: tenancy.fetch('current_balance'),
              latest_action: build_latest_action(tenancy),
              primary_contact: build_primary_contact(tenancy)
            }
          end
        end

        private

        def build_primary_contact(tenancy)
          return nil if tenancy.dig('primary_contact', 'name').nil?
          {
            name: tenancy.dig('primary_contact', 'name'),
            short_address: tenancy.dig('primary_contact', 'short_address'),
            postcode: tenancy.dig('primary_contact', 'postcode')
          }
        end

        def build_latest_action(tenancy)
          return nil if tenancy.dig('latest_action', 'code').nil?
          {
            code: tenancy.dig('latest_action', 'code'),
            date: Time.parse(tenancy.dig('latest_action', 'date'))
          }
        end

        def params_list(key, values)
          values.each_with_index.map do |value, index|
            "#{key}[#{index}]=#{value}"
          end.join('&')
        end
      end
    end
  end
end
