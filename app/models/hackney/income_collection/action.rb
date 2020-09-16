module Hackney
  module IncomeCollection
    class Action < ApplicationRecord
      enum service_area_type: {
        rent: 'rent', leasehold: 'leasehold'
      }
      validates :tenancy_ref, presence: true, uniqueness: true

      scope :not_paused, -> { where('pause_until <= ? OR pause_until IS NULL', Time.zone.now.beginning_of_day) }

      def paused?
        pause_until ? pause_until.future? : false
      end

      def metadata
        (self[:metadata]).symbolize_keys
      end
    end
  end
end
