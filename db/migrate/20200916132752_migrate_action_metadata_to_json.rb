class MigrateActionMetadataToJson < ActiveRecord::Migration[5.2]
  def change
    change_column :actions, :metadata, :json, using: 'metadata::JSON'
  end
end
