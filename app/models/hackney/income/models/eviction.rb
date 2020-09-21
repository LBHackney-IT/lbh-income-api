module Hackney
  module Income
    module Models
      class Eviction < ApplicationRecord
        validates_presence_of :tenancy_ref, :date
      end
    end
  end
end
