module Hackney
  module Income
    module Jobs
      class RequestPrecompiledLetterStateJob < ApplicationJob
        queue_as :default

        def perform(document_id:)
          Rails.logger.info("Starting RequestPrecompiledLetterStateJob for document_id #{document_id}")

          document = Hackney::Cloud::Document.find(document_id)
          income_use_case_factory.request_precompiled_letter_state.execute(
            document: document
          )
        end
      end
    end
  end
end
