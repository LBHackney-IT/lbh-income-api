class MigrateActionMetadataToJson < ActiveRecord::Migration[5.2]
  def change
    def change
      change_column :actions, :metadata, :json, using: 'metadata::JSON'
    end
  end
end
