module Hackney
  module Letter
    class AllDocumentsUseCase
      def initialize(cloud_storage:)
        @cloud_storage = cloud_storage
      end

      def execute
        @cloud_storage.all_documents.each do |doc|
          metadata = JSON.parse(doc.metadata).deep_symbolize_keys
          if metadata[:user_id]
            metadata[:user_name] = Hackney::Income::Models::User.find(metadata[:user_id]).name
            doc.metadata = metadata.to_json
          end
        end
      end
    end
  end
end
