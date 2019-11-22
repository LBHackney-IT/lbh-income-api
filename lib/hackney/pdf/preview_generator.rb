module Hackney
  module PDF
    class PreviewGenerator
      LOGO_PATH = 'lib/hackney/pdf/templates/layouts/logo.svg'.freeze
      SENDER_ADDRESS_PATH = 'lib/hackney/pdf/templates/layouts/sender_address.erb'.freeze
      SENDING_DATE_PATH = 'lib/hackney/pdf/templates/layouts/sending_date.erb'.freeze
      PAYMENT_OPTIONS_PATH = 'lib/hackney/pdf/templates/layouts/payment_options.erb'.freeze
      REPLY_FORM_PATH = 'lib/hackney/pdf/templates/layouts/reply_form.erb'.freeze
      REPLY_FORM_LBA_PATH = 'lib/hackney/pdf/templates/layouts/reply_form_lba.erb'.freeze
      FINANCIAL_STATEMENT_LBA_PATH = 'lib/hackney/pdf/templates/layouts/financial_statement_lba.erb'.freeze
      PAYMENT_TABLES_LBA_PATH = 'lib/hackney/pdf/templates/layouts/payment_tables_lba.erb'.freeze
      SIGNATURE_IMAGE = 'lib/hackney/pdf/templates/layouts/signature.png'.freeze

      def initialize(template_path:)
        @template_path = template_path
        @errors = []
        @sending_date = get_date
        @sending_date_lba = get_lba_date
        @return_date_lba = get_return_date
        @logo = File.open(LOGO_PATH).read
      end

      def execute(letter_params:, username:)
        @letter = Hackney::ServiceCharge::Letter.build(letter_params: letter_params, template_path: @template_path)

        @sender_address = ERB.new(File.open(SENDER_ADDRESS_PATH).read).result(binding)

        @sending_date = ERB.new(File.open(SENDING_DATE_PATH).read).result(binding)

        @payment_options = ERB.new(File.open(PAYMENT_OPTIONS_PATH).read).result(binding)

        @reply_form = ERB.new(File.open(REPLY_FORM_PATH).read).result(binding)

        @reply_form_lba = ERB.new(File.open(REPLY_FORM_LBA_PATH).read).result(binding)

        @financial_statement_lba = ERB.new(File.open(FINANCIAL_STATEMENT_LBA_PATH).read).result(binding)

        @payment_tables_lba = ERB.new(File.open(PAYMENT_TABLES_LBA_PATH).read).result(binding)

        @signature_base64 = Base64.encode64(File.open(SIGNATURE_IMAGE).read)

        @username = username
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

      def get_lba_date
        Time.now.strftime('%d %B %Y')
      end
    end
  end
end
