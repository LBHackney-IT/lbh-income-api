# GovNotify Documents to get responses for
# <= 7days old
# not uploading, failed, or accepted

module Hackney
  module Notification
    class EnqueueRequestAllPrecompiledLetterStates
      attr_accessor :enqueue_job, :document_store, :documents

      def initialize(enqueue_job: Hackney::Income::Jobs::RequestPrecompiledLetterStateJob, document_store: Hackney::Cloud::Document)
        self.enqueue_job = enqueue_job
        self.document_store = document_store
        self.documents =
          document_store.where('updated_at >= ?', Time.now - 7.days)
                        .where.not(status: %i[nil validation-failed received])
      end

      def execute
        documents.each do |document|
          enqueue_job.perform_later(document_id: document.id)
        end
      end
    end
  end
end
