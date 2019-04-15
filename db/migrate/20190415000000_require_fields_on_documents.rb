class RequireFieldsOnDocuments < ActiveRecord::Migration[5.2]
  def up
    add_index :documents, :uuid, unique: true
    change_column :documents, :uuid, :string, null: false
    change_column :documents, :mime_type, :string, null: false
    change_column :documents, :extension, :string, null: false
  end

  def down
    remove_index :documents, name: 'index_documents_on_uuid'
    change_column :documents, :uuid, :string, null: true
    change_column :documents, :mime_type, :string, null: true
    change_column :documents, :extension, :string, null: true
  end
end
