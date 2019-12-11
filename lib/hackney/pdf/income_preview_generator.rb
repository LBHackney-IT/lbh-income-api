module Hackney
  module PDF
    class IncomePreviewGenerator
      LOGO_PATH = 'lib/hackney/pdf/templates/layouts/logo.svg'.freeze
      HACKNEY_ADDRESS_PARTIAL = 'lib/hackney/pdf/templates/income/partials/hackney_address.html.erb'.freeze
      TENANT_ADDRESS_PARTIAL = 'lib/hackney/pdf/templates/income/partials/tenant_address.html.erb'.freeze
      PAYMENT_OPTIONS_PARTIAL = 'lib/hackney/pdf/templates/income/partials/payment_options.html.erb'.freeze

      def initialize(template_path:)
        @template_path = template_path
        @errors = []
        @today_date = get_sending_date
        @logo = File.open(LOGO_PATH).read
      end

      def execute(letter_params:, username:)
        @letter = Hackney::IncomeCollection::Letter.build(letter_params: letter_params, template_path: @template_path)

        @hackney_address = load_erb_file(HACKNEY_ADDRESS_PARTIAL)
        @tenant_address = load_erb_file(TENANT_ADDRESS_PARTIAL)
        @payment_options = load_erb_file(PAYMENT_OPTIONS_PARTIAL)

        template = File.open(@template_path).read
        html = ERB.new(template).result(binding)

        {
          html: html,
          errors: @letter.errors
        }
      end

      private

      def get_date
        (Time.now + 1.day).strftime('%d %B %Y')
      end

      def get_return_date
        30.days.from_now.strftime('%d %B %Y')
      end

      def get_sending_date
        Time.now.strftime('%d %B %Y')
      end

      def load_erb_file(file_path)
        ERB.new(File.open(file_path).read).result(binding)
      end
    end
  end
end
