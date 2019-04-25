require 'pdfkit'

module Hackney
  module PDF
    class Generator
      PDF_STYLES = 'lib/hackney/pdf/templates/pdf_styles.css'.freeze

      def execute(html)
        kit = PDFKit.new(html, pdf_options)
        kit.stylesheets << PDF_STYLES
        kit
      end

      private

      def pdf_options
        {
          disable_smart_shrinking: false,
          page_size: 'A4',
          margin_top: '0.19685in',
          margin_right: '0.590551in',
          margin_bottom: '0.23000in',
          margin_left: '0.590551in'
        }
      end
    end
  end
end
