module Hackney
  module Income
    module Models
      class User < ApplicationRecord
        has_many :tenancies, foreign_key: :assigned_user_id
      end
    end
  end
end
