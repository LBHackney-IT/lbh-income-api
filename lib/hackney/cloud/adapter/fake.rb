module Hackney
  module Cloud
    module Adapter
      class Fake
        def upload(bucket_name:, filename:, new_filename:)
          "https://#{bucket_name}/#{new_filename}"
        end
      end
    end
  end
end
