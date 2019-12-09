module Hackney
  module Income
    module Jobs
      class SaveAndSendLetterJob < ApplicationJob
        UPLOADED_CLOUD_STATUS = :uploaded
        queue_as :cloud_storage

        after_perform do
          Rails.logger.info 'after_perform enqueuing send letter to gov notify'
          Hackney::Income::Jobs::SendLetterToGovNotifyJob.perform_now(document_id: @document_id, tenancy_ref: nil)
        end

        def perform(letter_html:, bucket_name:, filename:, document_id:)
          @document_id = document_id
          binary_letter_content = generate_pdf_binary(letter_html, document.uuid)

          Rails.logger.info "uploading document: #{document_id} - #{filename} to #{bucket_name}"
          response = cloud_provider.upload(bucket_name: bucket_name,
                                           binary_letter_content: binary_letter_content,
                                           filename: filename)

          document.update!(url: response[:url], status: UPLOADED_CLOUD_STATUS)
        end

        def cloud_provider
          Rails.configuration.cloud_adapter
        end

        private

        def document
          @document ||= Hackney::Cloud::Document.find(@document_id)
        end

        def generate_pdf_binary(letter_html, uuid)
          @pdf_generator = Hackney::PDF::Generator.new
          pdf_obj = @pdf_generator.execute(letter_html)
          file_obj = pdf_obj.to_file("tmp/#{uuid}.pdf")
          File.delete("tmp/#{uuid}.pdf")
          file_obj
        end
      end
    end
  end
end
