module Hackney
  module Income
    module Models
      class EvictionDate < ApplicationRecord
        validates_presence_of :tenancy_ref
      end
    end
  end
end
