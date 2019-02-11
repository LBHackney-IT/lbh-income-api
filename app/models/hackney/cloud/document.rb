module Hackney
  module Cloud
    class Document < ApplicationRecord
      enum status: { uploading: 0, uploaded: 1 }
    end
  end
end
