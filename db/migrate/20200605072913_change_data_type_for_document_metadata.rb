class ChangeDataTypeForDocumentMetadata < ActiveRecord::Migration[5.2]
  def change
    change_table :documents do |t|
      t.change :metadata, :text
    end
  end
end
