module Hackney
  module PDF
    class PreviewGenerator
      LOGO_PATH = 'lib/hackney/pdf/templates/layouts/logo.svg'.freeze
      SENDER_ADDRESS_PATH = 'lib/hackney/pdf/templates/layouts/sender_address.erb'.freeze
      SENDING_DATE_PATH = 'lib/hackney/pdf/templates/layouts/sending_date.erb'.freeze
      PAYMENT_OPTIONS_PATH = 'lib/hackney/pdf/templates/layouts/payment_options.erb'.freeze
      REPLY_FORM_PATH = 'lib/hackney/pdf/templates/layouts/reply_form.erb'.freeze
      PAYMENT_OPTIONS_LBA_PATH = 'lib/hackney/pdf/templates/layouts/payment_options_lba.erb'.freeze
      REPLY_FORM_LBA_PATH = 'lib/hackney/pdf/templates/layouts/reply_form_lba.erb'.freeze
      FINANCIAL_STATEMENT_LBA_PATH = 'lib/hackney/pdf/templates/layouts/financial_statement_lba.erb'.freeze
      PAYMENT_TABLES_LBA_PATH = 'lib/hackney/pdf/templates/layouts/payment_tables_lba.erb'.freeze
  
      def initialize(template_path:)
        @template_path = template_path
        @errors = []
        @sending_date = get_date
        @return_date_lba = get_return_date
        @logo = File.open(LOGO_PATH).read
      end

      def execute(letter_params:)
        @letter = Hackney::ServiceCharge::Letter.new(letter_params)

        @sender_address = ERB.new(File.open(SENDER_ADDRESS_PATH).read).result(binding)

        @sending_date = ERB.new(File.open(SENDING_DATE_PATH).read).result(binding)

        @payment_options = ERB.new(File.open(PAYMENT_OPTIONS_PATH).read).result(binding)

        @reply_form = ERB.new(File.open(REPLY_FORM_PATH).read).result(binding)

        @payment_options_lba = ERB.new(File.open(PAYMENT_OPTIONS_LBA_PATH).read).result(binding)

        @reply_form_lba = ERB.new(File.open(REPLY_FORM_LBA_PATH).read).result(binding)

        @financial_statement_lba = ERB.new(File.open(FINANCIAL_STATEMENT_LBA_PATH).read).result(binding)

        @payment_tables_lba = ERB.new(File.open(PAYMENT_TABLES_LBA_PATH).read).result(binding)

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
      (Time.now + 31.days).strftime('%d %B %Y')
      end
    end
  end
end
