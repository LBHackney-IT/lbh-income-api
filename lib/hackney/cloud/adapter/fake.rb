module Hackney
  module Cloud
    module Adapter
      class Fake
        def upload(bucketname, _filename, new_filename)
          "https://#{bucketname}/#{new_filename}"
        end
      end
    end
  end
end
