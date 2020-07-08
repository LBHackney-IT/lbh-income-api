module Hackney
  module Leasehold
    class CaseAttributes < ApplicationRecord
      self.table_name = 'leasehold_case_attributes' # Hackney::Leasehold::CaseAttributes

      validates :tenancy_ref, presence: true, uniqueness: true

      def paused?
        is_paused_until ? is_paused_until.future? : false
      end

      def self.not_paused
        where('is_paused_until <= ? OR is_paused_until IS NULL', Time.zone.now.beginning_of_day)
      end
    end
  end
end
